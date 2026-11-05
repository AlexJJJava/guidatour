import { SUPABASE_URL } from '../config.js'
import { HttpError, notFound, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'

export const ROLES = ['turista', 'guida', 'accompagnatore', 'tourOperator'] as const
export type Role = (typeof ROLES)[number]

// Le registrazioni professionali restano in_attesa finché un admin non decide.
export const APPROVAL_STATUSES = ['in_attesa', 'approvato', 'rifiutato', 'sospeso'] as const
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
  roles: Role[]
  // Ruoli aggiunti dal profilo, in attesa dell'admin (migrazione 0008).
  pendingRoles: Role[]
  avatarUrl: string | null
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
  // Tutti i ruoli professionali; `role` è il principale.
  roles: Role[]
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
  // Assente finché la migrazione 0006 non è applicata.
  roles?: Role[] | null
  pending_roles?: Role[] | null
  // Assente finché la migrazione 0005 non è applicata.
  avatar_url?: string | null
  languages: string[]
  bio: string
  city: string
  created_at: string
}

// La vista espone solo colonne pubbliche; con '*' include anche `roles` dalla 0006.
const PUBLIC_PROFILE_COLUMNS = '*'

/** Ruoli professionali di un profilo, anche prima della migrazione 0006. */
export const rolesOf = (p: { role: Role; roles?: Role[] | null }): Role[] =>
  p.roles?.length ? p.roles : p.role === 'turista' ? [] : [p.role]

const toPublic = (p: PublicProfile): PublicProfile => ({ ...p, roles: rolesOf(p) })

/** Solo accompagnatore: niente visite guidate né testi su beni culturali. */
export const onlyAccompagnatore = (p: { role: Role; roles?: Role[] | null }) => {
  const roles = rolesOf(p)
  return roles.includes('accompagnatore') && !roles.includes('guida') && !roles.includes('tourOperator')
}

const toProfile = (r: ProfileRow): Profile => ({
  id: r.id,
  name: r.name,
  email: r.email,
  role: r.role,
  provider: r.provider,
  verified: r.verified,
  isAdmin: r.is_admin,
  approvalStatus: r.approval_status ?? 'approvato',
  roles: rolesOf(r),
  pendingRoles: r.pending_roles ?? [],
  avatarUrl: r.avatar_url ?? null,
  languages: r.languages,
  bio: r.bio,
  city: r.city,
  createdAt: r.created_at,
})

export const isProfessional = (p: { role: Role; roles?: Role[] | null }) => rolesOf(p).length > 0

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
  const query = () =>
    db.from('profiles').select('*').neq('role', 'turista').order('created_at', { ascending: false })
  // "In attesa" comprende i professionisti che hanno chiesto nuovi ruoli.
  if (status === 'in_attesa') {
    const both = await query()
      .or('approval_status.eq.in_attesa,pending_roles.neq.{}')
      .returns<ProfileRow[]>()
    // Prima della migrazione 0008 la colonna pending_roles non esiste.
    if (!both.error) return both.data.map(toProfile)
  }
  return unwrap(await query().eq('approval_status', status).returns<ProfileRow[]>()).map(toProfile)
}

/** Chiede di cambiare i propri ruoli professionali (migrazione 0008). */
export async function requestRoles(db: Db, userId: string, roles: Role[]): Promise<Profile> {
  unwrap(await db.rpc('request_roles', { p_roles: roles }))
  return getMyProfile(db, userId)
}

export async function setApprovalStatus(
  db: Db,
  userId: string,
  status: 'approvato' | 'rifiutato' | 'sospeso',
): Promise<void> {
  unwrap(await db.rpc('set_approval_status', { p_user: userId, p_status: status }))
}

export async function updateMyProfile(
  db: Db,
  userId: string,
  patch: {
    name?: string
    bio?: string
    languages?: string[]
    city?: string
    avatarUrl?: string | null
  },
): Promise<Profile> {
  const { avatarUrl, ...fields } = patch
  // Solo una foto caricata dall'utente nella propria cartella.
  if (avatarUrl && !avatarUrl.startsWith(`${SUPABASE_URL}/storage/v1/object/public/avatars/${userId}/`)) {
    throw new HttpError(422, 'Indirizzo della foto non valido')
  }
  const row = unwrap(
    await db
      .from('profiles')
      .update({ ...fields, ...(avatarUrl !== undefined && { avatar_url: avatarUrl }) })
      .eq('id', userId)
      .select('*')
      .single<ProfileRow>(),
  )
  return toProfile(row)
}

export async function listProfessionals(db: Db, role?: Role): Promise<PublicProfile[]> {
  const rows = unwrap(
    await db.from('public_profiles').select(PUBLIC_PROFILE_COLUMNS).order('name').returns<PublicProfile[]>(),
  ).map(toPublic)
  return role ? rows.filter((p) => p.roles.includes(role)) : rows
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
  return toPublic(row)
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
  return new Map(rows.map((p) => [p.id, toPublic(p)]))
}
