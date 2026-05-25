import { Router } from 'express';
import { createSubject, listSubjectsForCollege } from './subjects.controller';
import { authenticate, requireVerifiedEmail } from '../../shared/middlewares/auth.middleware';

const router = Router();

/**
 * @openapi
 * /api/v1/subjects/college/{collegeId}:
 *   get:
 *     summary: List subjects for a specific college
 *     description: Public endpoint to list active subjects for a given college. Requires App Check in production but no Firebase Auth token.
 *     tags: [Subjects]
 *     security:
 *       - appCheck: []
 *     parameters:
 *       - in: path
 *         name: collegeId
 *         required: true
 *         schema:
 *           type: string
 *           example: "col_123"
 *     responses:
 *       200:
 *         description: List of subjects.
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                     example: "sub_123"
 *                   name:
 *                     type: string
 *                     example: "Operating Systems"
 *                   code:
 *                     type: string
 *                     example: "CS8493"
 *                   department:
 *                     type: string
 *                     example: "Computer Science"
 *                   semester:
 *                     type: integer
 *                     example: 4
 */
router.get('/college/:collegeId', listSubjectsForCollege);

/**
 * @openapi
 * /api/v1/subjects:
 *   post:
 *     summary: User creates a new subject for their college
 *     description: If a subject is missing from their college directory, a user can create it. Superadmins can pass any `collegeId`.
 *     tags: [Subjects]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Compiler Design"
 *               code:
 *                 type: string
 *                 example: "CS8602"
 *               department:
 *                 type: string
 *                 example: "Computer Science"
 *               semester:
 *                 type: integer
 *                 example: 6
 *               credits:
 *                 type: integer
 *                 example: 4
 *               collegeId:
 *                 type: string
 *                 description: Required for Superadmins. For normal users, it inherits from their profile.
 *                 example: "col_123"
 *             required:
 *               - name
 *               - code
 *     responses:
 *       201:
 *         description: Subject created successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Subject created"
 *                 id:
 *                   type: string
 *                   example: "sub_456"
 */
router.post('/', authenticate, requireVerifiedEmail, createSubject);

export default router;
