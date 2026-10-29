import { HttpError, notFound, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'

export const ROLES = ['turista', 'guida', 'accompagnatore', 'tourOperator'] as const
export type Role = (typeof ROLES)[number]

// Le registrazioni professionali restano in_attesa finché un admin non decide.
export const APPROVAL_STATUSES = ['in_attesa', 'approvato', 'rifiutato'] as const
export type ApprovalStatus = (typeof APPROVAL_STATUSES)[number]

export interface Profile {
  id: string
  name: string
  email: string
  role: Role
  provider: string
  verified: boolean
  isAdmin: boolean
  approvalStatus: ApprovalStatus
  languages: string[]
  bio: string
  city: string
  createdAt: string
}

// Profilo visibile a tutti: niente email né flag amministrativi.
export interface PublicProfile {
  id: string
  name: string
  role: Role
  verified: boolean
  languages: string[]
  bio: string
  city: string
}

type ProfileRow = {
  id: string
  name: string
  email: string
  role: Role
  provider: string
  verified: boolean
  is_admin: boolean
  // Assente finché la migrazione 0004 non è applicata.
  approval_status?: ApprovalStatus
  languages: string[]
  bio: string
  city: string
  created_at: string
}

const PUBLIC_PROFILE_COLUMNS = 'id, name, role, verified, languages, bio, city'

const toProfile = (r: ProfileRow): Profile => ({
  id: r.id,
  name: r.name,
  email: r.email,
  role: r.role,
  provider: r.provider,
  verified: r.verified,
  isAdmin: r.is_admin,
  approvalStatus: r.approval_status ?? 'approvato',
  languages: r.languages,
  bio: r.bio,
  city: r.city,
  createdAt: r.created_at,
})

export const isProfessional = (p: { role: Role }) => p.role !== 'turista'

export async function getMyProfile(db: Db, userId: string): Promise<Profile> {
  const row = unwrap(
    await db.from('profiles').select('*').eq('id', userId).maybeSingle<ProfileRow>(),
  )
  // Il profilo lo crea un trigger alla registrazione: se manca, lo schema
  // non è stato applicato correttamente.
  if (!row) throw new HttpError(404, 'Profilo non trovato')
  return toProfile(row)
}

export async function requireProfessional(db: Db, userId: string): Promise<Profile> {
  const profile = await getMyProfile(db, userId)
  if (!isProfessional(profile)) {
    throw new HttpError(403, 'Funzione riservata a guide, accompagnatori e tour operator')
  }
  if (profile.approvalStatus !== 'approvato') {
    throw new HttpError(403, 'Account non ancora approvato da un amministratore')
  }
  return profile
}

export async function requireAdmin(db: Db, userId: string): Promise<Profile> {
  const profile = await getMyProfile(db, userId)
  if (!profile.isAdmin) throw new HttpError(403, 'Riservato agli amministratori')
  return profile
}

// Registrazioni professionali per la pagina delle approvazioni (solo admin:
// la policy profiles_select_admin rende visibili i profili altrui).
export async function listRegistrations(db: Db, status: ApprovalStatus): Promise<Profile[]> {
  const rows = unwrap(
    await db
      .from('profiles')
      .select('*')
      .neq('role', 'turista')
      .eq('approval_status', status)
      .order('created_at', { ascending: false })
      .returns<ProfileRow[]>(),
  )
  return rows.map(toProfile)
}

export async function setApprovalStatus(
  db: Db,
  userId: string,
  status: 'approvato' | 'rifiutato',
): Promise<void> {
  unwrap(await db.rpc('set_approval_status', { p_user: userId, p_status: status }))
}

export async function updateMyProfile(
  db: Db,
  userId: string,
  patch: { name?: string; bio?: string; languages?: string[]; city?: string },
): Promise<Profile> {
  const row = unwrap(
    await db.from('profiles').update(patch).eq('id', userId).select('*').single<ProfileRow>(),
  )
  return toProfile(row)
}

export async function listProfessionals(db: Db, role?: Role): Promise<PublicProfile[]> {
  let query = db.from('public_profiles').select(PUBLIC_PROFILE_COLUMNS).order('name')
  if (role) query = query.eq('role', role)
  return unwrap(await query.returns<PublicProfile[]>())
}

export async function getPublicProfile(db: Db, id: string): Promise<PublicProfile> {
  const row = unwrap(
    await db
      .from('public_profiles')
      .select(PUBLIC_PROFILE_COLUMNS)
      .eq('id', id)
      .maybeSingle<PublicProfile>(),
  )
  if (!row) throw notFound('Profilo')
  return row
}

export async function getPublicProfiles(
  db: Db,
  ids: string[],
): Promise<Map<string, PublicProfile>> {
  const unique = [...new Set(ids)]
  if (unique.length === 0) return new Map()
  const rows = unwrap(
    await db
      .from('public_profiles')
      .select(PUBLIC_PROFILE_COLUMNS)
      .in('id', unique)
      .returns<PublicProfile[]>(),
  )
  return new Map(rows.map((p) => [p.id, p]))
}
