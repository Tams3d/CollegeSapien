import { Router } from 'express';
import {
  getSyllabus,
  getHubResources,
  uploadResource,
  updateResourceFileUrl,
  reportResource,
} from './resources.controller';
import { authenticate, requireVerifiedEmail } from '../../shared/middlewares/auth.middleware';

const router = Router();

/**
 * @openapi
 * /api/v1/resources/syllabus:
 *   get:
 *     summary: Filter syllabus by college, department, semester
 *     description: Retrieve a list of syllabus materials filtered by query parameters.
 *     tags: [Resources]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: The department to filter by.
 *         example: "Computer Science"
 *       - in: query
 *         name: semester
 *         schema:
 *           type: integer
 *         description: The semester number to filter by.
 *         example: 5
 *       - in: query
 *         name: query
 *         schema:
 *           type: string
 *         description: Search query for subject name or code.
 *         example: "Data Structures"
 *     responses:
 *       200:
 *         description: A list of syllabus documents.
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                     example: "doc_123"
 *                   name:
 *                     type: string
 *                     example: "Engineering Mathematics"
 *                   code:
 *                     type: string
 *                     example: "MA8151"
 *                   department:
 *                     type: string
 *                     example: "Computer Science"
 *                   semester:
 *                     type: integer
 *                     example: 1
 *                   link:
 *                     type: string
 *                     example: "https://example.com/syllabus.pdf"
 *       500:
 *         description: Internal server error.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Internal Server Error"
 */
router.get('/syllabus', authenticate, requireVerifiedEmail, getSyllabus);

/**
 * @openapi
 * /api/v1/resources/hub:
 *   get:
 *     summary: View notes and question papers
 *     description: Retrieve crowd-sourced notes and question papers.
 *     tags: [Resources]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [Notes, QP, Syllabus]
 *         description: The category of resource.
 *         example: "Notes"
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *         description: The file type.
 *         example: "PDF"
 *     responses:
 *       200:
 *         description: A list of hub resources.
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                     example: "res_456"
 *                   name:
 *                     type: string
 *                     example: "Unit 1 Notes - OS"
 *                   category:
 *                     type: string
 *                     example: "Notes"
 *                   type:
 *                     type: string
 *                     example: "PDF"
 *                   department:
 *                     type: string
 *                     example: "Computer Science"
 *                   uploadedBy:
 *                     type: string
 *                     example: "user_789"
 *                   status:
 *                     type: string
 *                     example: "approved"
 *       500:
 *         description: Internal server error.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Internal Server Error"
 */
router.get('/hub', authenticate, requireVerifiedEmail, getHubResources);

/**
 * @openapi
 * /api/v1/resources/upload:
 *   post:
 *     summary: Create resource metadata after Firebase Storage upload
 *     description: |
 *       The Flutter app uploads the file bytes directly to Firebase Storage at
 *       `resources/{resourceId}/{fileName}` using Storage rules, then calls this endpoint with
 *       metadata. This API does not accept multipart file bytes.
 *     tags: [Resources]
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
 *               id:
 *                 type: string
 *                 description: Optional client-generated resource ID used in the Storage path.
 *                 example: "88f9e458-7d4d-4e93-8c19-12130bb6d961"
 *               name:
 *                 type: string
 *                 example: "Unit 2 OS Notes"
 *               category:
 *                 type: string
 *                 enum: [Notes, QP]
 *                 example: "Notes"
 *               department:
 *                 type: string
 *                 example: "Computer Science"
 *               semester:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 10
 *                 example: 5
 *               subjectId:
 *                 type: string
 *                 example: "subject_doc_id"
 *               storagePath:
 *                 type: string
 *                 example: "resources/88f9e458-7d4d-4e93-8c19-12130bb6d961/os-notes.pdf"
 *               fileUrl:
 *                 type: string
 *                 format: uri
 *                 example: "https://firebasestorage.googleapis.com/v0/b/codesapien-college.appspot.com/o/resources%2F..."
 *               fileName:
 *                 type: string
 *                 example: "os-notes.pdf"
 *               mimeType:
 *                 type: string
 *                 example: "application/pdf"
 *               sizeBytes:
 *                 type: integer
 *                 maximum: 26214400
 *                 example: 420000
 *             required:
 *               - name
 *               - category
 *     responses:
 *       201:
 *         description: Resource uploaded successfully, pending moderation.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Resource uploaded and pending moderation"
 *                 id:
 *                   type: string
 *                   example: "new_res_id"
 *       400:
 *         description: Bad request.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Validation failed"
 */
router.post('/upload', authenticate, requireVerifiedEmail, uploadResource);
router.patch('/:id', authenticate, requireVerifiedEmail, updateResourceFileUrl);

/**
 * @openapi
 * /api/v1/resources/report:
 *   post:
 *     summary: Report a resource/user
 *     description: Report inappropriate content or users.
 *     tags: [Resources]
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
 *               resourceId:
 *                 type: string
 *                 example: "res_456"
 *               reason:
 *                 type: string
 *                 example: "Contains spam or unrelated content."
 *               type:
 *                 type: string
 *                 enum: [spam, incorrect, abusive, low_quality]
 *                 example: "spam"
 *             required:
 *               - resourceId
 *               - reason
 *               - type
 *     responses:
 *       201:
 *         description: Report submitted successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Report submitted"
 *       400:
 *         description: Bad request.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Invalid report reason"
 */
router.post('/report', authenticate, requireVerifiedEmail, reportResource);

export default router;
