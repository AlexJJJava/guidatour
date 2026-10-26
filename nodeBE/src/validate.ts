import type { Context } from 'hono'
import { z } from 'zod'
import { HttpError } from './errors.js'

export async function parseBody<T extends z.ZodType>(c: Context, schema: T): Promise<z.infer<T>> {
  let body: unknown
  try {
    body = await c.req.json()
  } catch {
    throw new HttpError(400, 'Body JSON non valido')
  }
  return parse(schema, body)
}

export function parseQuery<T extends z.ZodType>(c: Context, schema: T): z.infer<T> {
  return parse(schema, c.req.query())
}

function parse<T extends z.ZodType>(schema: T, value: unknown): z.infer<T> {
  const result = schema.safeParse(value)
  if (!result.success) {
    const issue = result.error.issues[0]
    const field = issue.path.join('.')
    throw new HttpError(400, field ? `${field}: ${issue.message}` : issue.message)
  }
  return result.data
}
