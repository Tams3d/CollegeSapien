import { z } from 'zod';

/**
 * @openapi
 * components:
 *   schemas:
 *     Subject:
 *       type: object
 *       required:
 *         - name
 *         - code
 *         - collegeId
 *       properties:
 *         name:
 *           type: string
 *           minLength: 2
 *         code:
 *           type: string
 *           minLength: 2
 *         collegeId:
 *           type: string
 *         department:
 *           type: string
 *         semester:
 *           type: integer
 *           minimum: 1
 *           maximum: 10
 *         credits:
 *           type: integer
 *           minimum: 1
 *           maximum: 10
 *         createdBy:
 *           type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *         deletedAt:
 *           type: string
 *           format: date-time
 *           nullable: true
 */
export const SubjectSchema = z.object({
  name: z.string().min(2),
  code: z.string().min(2),
  collegeId: z.string(),
  department: z.string().optional(),
  semester: z.number().int().min(1).max(10).optional(),
  credits: z.number().int().min(1).max(10).optional(),
  createdBy: z.string().optional(),
  createdAt: z.any().optional(),
  updatedAt: z.any().optional(),
  deletedAt: z.any().optional().nullable(),
});

export type Subject = z.infer<typeof SubjectSchema>;
