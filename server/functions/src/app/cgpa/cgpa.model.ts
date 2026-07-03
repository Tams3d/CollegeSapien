import { z } from 'zod';

/**
 * @openapi
 * components:
 *   schemas:
 *     InternalMarks:
 *       type: object
 *       required:
 *         - subjectId
 *         - internalMarks
 *         - targetGrade
 *       properties:
 *         subjectId:
 *           type: string
 *           description: ID of the subject
 *         internalMarks:
 *           type: number
 *           description: Marks obtained internally
 *         maxInternalMarks:
 *           type: number
 *           default: 40
 *           description: Maximum possible internal marks
 *         targetGrade:
 *           type: string
 *           enum: [O, A+, A, B+, B]
 *           description: The grade the student wants to achieve
 */
export const InternalMarksSchema = z.object({
  subjectId: z.string(),
  internalMarks: z.number().min(0),
  maxInternalMarks: z.number().min(1).default(40),
  targetGrade: z.enum(['O', 'A+', 'A', 'B+', 'B']),
});

export type InternalMarks = z.infer<typeof InternalMarksSchema>;

export const SemesterEntrySchema = z.object({
  semester: z.number().int().min(1),
  gpa: z.number().min(0).max(10),
  credits: z.number().int().min(1),
});

export const SemestersSchema = z.object({
  semesters: z.array(SemesterEntrySchema),
});

export type SemesterEntry = z.infer<typeof SemesterEntrySchema>;
export type Semesters = z.infer<typeof SemestersSchema>;
