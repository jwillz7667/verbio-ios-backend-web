// Error handler for API routes

import { NextResponse } from 'next/server'
import { ZodError } from 'zod'
import { AppError, ValidationError, InternalServerError } from './AppError'

interface ErrorResponse {
  error: string
  message: string
  statusCode: number
  errors?: Record<string, string[]>
}

export function handleError(error: unknown): NextResponse<ErrorResponse> {
  // Log error for debugging
  console.error('API Error:', error)

  // Handle AppError instances
  if (error instanceof AppError) {
    const response: ErrorResponse = {
      error: error.code,
      message: error.message,
      statusCode: error.statusCode,
    }

    if (error instanceof ValidationError) {
      response.errors = error.errors
    }

    return NextResponse.json(response, { status: error.statusCode })
  }

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    const errors: Record<string, string[]> = {}

    for (const issue of error.issues) {
      const path = issue.path.join('.')
      if (!errors[path]) {
        errors[path] = []
      }
      errors[path].push(issue.message)
    }

    const validationError = new ValidationError('Validation failed', errors)
    return NextResponse.json(validationError.toJSON(), { status: 422 })
  }

  // Handle generic errors
  const internalError = new InternalServerError(
    process.env.NODE_ENV === 'development'
      ? (error as Error).message
      : 'An unexpected error occurred'
  )

  return NextResponse.json(internalError.toJSON(), { status: 500 })
}

// Type guard for checking if error is operational
export function isOperationalError(error: unknown): boolean {
  if (error instanceof AppError) {
    return error.isOperational
  }
  return false
}
