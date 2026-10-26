import { HttpError, notFound, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'

export const ROLES = ['turista', 'guida', 'accompagnatore', 'tourOperator'] as const
export type Role = (typeof ROLES)[number]

export interface Profile {
  id: string
  name: string
  email: string
  role: Role
  provider: string
  verified: boolean
  isAdmin: boolean
  languages: string[]
  bio: string
}

// Profilo visibile a tutti: niente email né flag amministrativi.
export interface PublicProfile {
  id: string
  name: string
  role: Role
  verified: boolean
  languages: string[]
  bio: string
}

type ProfileRow = {
  id: string
  name: string
  email: string
  role: Role
  provider: string
  verified: boolean
  is_admin: boolean
  languages: string[]
  bio: string
}

const PUBLIC_PROFILE_COLUMNS = 'id, name, role, verified, languages, bio'

const toProfile = (r: ProfileRow): Profile => ({
  id: r.id,
  name: r.name,
  email: r.email,
  role: r.role,
  provider: r.provider,
  verified: r.verified,
  isAdmin: r.is_admin,
  languages: r.languages,
  bio: r.bio,
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
  return profile
}

export async function updateMyProfile(
  db: Db,
  userId: string,
  patch: { name?: string; bio?: string; languages?: string[] },
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
