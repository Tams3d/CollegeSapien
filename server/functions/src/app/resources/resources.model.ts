import { z } from 'zod';

/**
 * @openapi
 * components:
 *   schemas:
 *     Report:
 *       type: object
 *       required:
 *         - resourceId
 *         - reason
 *         - type
 *       properties:
 *         resourceId:
 *           type: string
 *         reason:
 *           type: string
 *           minLength: 5
 *         reportedBy:
 *           type: string
 *         type:
 *           type: string
 *           enum: [spam, incorrect, abusive, low_quality]
 *         status:
 *           type: string
 *           enum: [pending, resolved, dismissed]
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
 *     HubResource:
 *       type: object
 *       required:
 *         - name
 *         - category
 *       properties:
 *         name:
 *           type: string
 *         category:
 *           type: string
 *           enum: [Notes, QP, Syllabus]
 *         department:
 *           type: string
 *         regulation:
 *           type: string
 *           maxLength: 20
 *         subjectId:
 *           type: string
 *         subjectName:
 *           type: string
 *         uploadedBy:
 *           type: string
 *         status:
 *           type: string
 *           enum: [pending_moderation, approved, rejected]
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
export const ReportSchema = z.object({
  resourceId: z.string(),
  reason: z.string().min(5),
  type: z.enum(['spam', 'incorrect', 'abusive', 'low_quality']),
  createdAt: z.any().optional(),
  updatedAt: z.any().optional(),
  deletedAt: z.any().optional().nullable(),
});

export type Report = z.infer<typeof ReportSchema>;

export const HubResourceSchema = z.object({
  id: z
    .string()
    .regex(/^[A-Za-z0-9_-]{8,80}$/)
    .optional(),
  name: z.string().min(2),
  category: z.enum(['Notes', 'QP', 'Syllabus']),
  department: z.string().optional(),
  semester: z.number().int().min(1).max(10).optional(),
  regulation: z.string().max(20).optional(),
  subjectId: z.string().optional(),
  subjectName: z.string().optional(),
  collegeId: z.string().optional(),
  fileUrl: z.string().url().optional(),
  storagePath: z.string().optional(),
  fileName: z.string().optional(),
  mimeType: z.string().optional(),
  sizeBytes: z
    .number()
    .int()
    .min(0)
    .max(25 * 1024 * 1024)
    .optional(),
  uploadedBy: z.string().optional(),
  status: z.enum(['pending_moderation', 'approved', 'rejected']).default('pending_moderation'),
  keywords: z.array(z.string()).optional(),
  aiSuggestedCategory: z.enum(['Notes', 'QP', 'Syllabus']).nullable().optional(),
  aiSpamFlag: z.boolean().optional().default(false),
  aiProcessed: z.boolean().optional().default(false),
  createdAt: z.any().optional(),
  updatedAt: z.any().optional(),
  deletedAt: z.any().optional().nullable(),
});

export type HubResource = z.infer<typeof HubResourceSchema>;
