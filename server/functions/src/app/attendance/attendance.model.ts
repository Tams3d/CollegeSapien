import { z } from 'zod';

/**
 * @openapi
 * components:
 *   schemas:
 *     Attendance:
 *       type: object
 *       required:
 *         - subjectId
 *         - date
 *         - status
 *       properties:
 *         subjectId:
 *           type: string
 *         date:
 *           type: string
 *           format: date
 *         status:
 *           type: string
 *           enum: [Present, Absent, Leave, OD_ML, None]
 */

export const AttendanceSchema = z
  .object({
    subjectId: z.string(),
    date: z.string().optional(), // Legacy ISO format
    dateKey: z
      .string()
      .regex(/^\d{4}-\d{2}-\d{2}$/)
      .optional(),
    slotStartTime: z.string().optional(),
    slotEndTime: z.string().optional(),
    status: z.enum(['Present', 'Absent', 'Leave', 'OD_ML', 'None']),
  })
  .refine(data => data.date || data.dateKey, {
    message: 'dateKey or date is required',
  });

export type Attendance = z.infer<typeof AttendanceSchema>;

export const AttendanceSyncSchema = z.object({
  updates: z.array(AttendanceSchema).min(1).max(400),
});

/**
 * @openapi
 * components:
 *   schemas:
 *     AttendanceSummary:
 *       type: object
 *       properties:
 *         subjectId:
 *           type: string
 *         subjectName:
 *           type: string
 *         attended:
 *           type: integer
 *         total:
 *           type: integer
 *         percentage:
 *           type: number
 *         safeToSkip:
 *           type: integer
 */
