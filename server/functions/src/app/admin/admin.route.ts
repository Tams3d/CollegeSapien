import { Router } from 'express';
import {
  assignRole,
  listUsers,
  resolveReport,
  getUserById,
  banUser,
  unbanUser,
  getResourceStats,
  unarchiveResource,
  getCmsContent,
  updateCmsContent,
} from './admin.controller';
import {
  getReports,
  deleteResource,
  listPendingResources,
  listApprovedResources,
  listArchivedResources,
  approveResource,
  rejectResource,
} from '../resources/resources.controller';
import { authenticate, requireVerifiedEmail } from '../../shared/middlewares/auth.middleware';
import { isSuperAdmin, isModerator } from '../../shared/middlewares/role.middleware';

const router = Router();

/**
 * @openapi
 * /api/v1/admin/assign-role:
 *   post:
 *     summary: Assign a role to a user (SuperAdmin only)
 *     description: Assigns roles like `moderator` or `superadmin`. Can be scoped to a `collegeId`.
 *     tags: [Admin]
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
 *               uid:
 *                 type: string
 *                 example: "user_id_123"
 *               role:
 *                 type: string
 *                 enum: [user, moderator, admin, superadmin]
 *                 example: "moderator"
 *               collegeId:
 *                 type: string
 *                 example: "col_123"
 *             required:
 *               - uid
 *               - role
 *     responses:
 *       200:
 *         description: Role assigned successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Role moderator assigned to user user_id_123"
 */
router.post('/assign-role', authenticate, requireVerifiedEmail, isSuperAdmin, assignRole);

/**
 * @openapi
 * /api/v1/admin/users:
 *   get:
 *     summary: List all users (SuperAdmin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     responses:
 *       200:
 *         description: A list of users.
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                   email:
 *                     type: string
 *                   name:
 *                     type: string
 */
router.get('/users', authenticate, requireVerifiedEmail, isSuperAdmin, listUsers);
router.get('/users/:id', authenticate, requireVerifiedEmail, isSuperAdmin, getUserById);
router.patch('/users/:id/ban', authenticate, requireVerifiedEmail, isSuperAdmin, banUser);
router.patch('/users/:id/unban', authenticate, requireVerifiedEmail, isSuperAdmin, unbanUser);

/**
 * @openapi
 * /api/v1/admin/reports:
 *   get:
 *     summary: Get pending reports (Moderator/Admin/SuperAdmin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     responses:
 *       200:
 *         description: A list of pending reports.
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                   resourceId:
 *                     type: string
 *                   reason:
 *                     type: string
 *                   type:
 *                     type: string
 *                   status:
 *                     type: string
 *                     example: "pending"
 */
router.get('/reports', authenticate, requireVerifiedEmail, isModerator, getReports);

/**
 * @openapi
 * /api/v1/admin/reports/{id}/resolve:
 *   patch:
 *     summary: Resolve a report (Moderator/Admin/SuperAdmin)
 *     description: Take action on a pending report. delete_resource archives the
 *       resource and resolves pending reports for it.
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               action:
 *                 type: string
 *                 enum: [dismiss, ban_user, delete_resource]
 *                 example: "delete_resource"
 *             required:
 *               - action
 *     responses:
 *       200:
 *         description: Report resolved.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Report resolved with action: delete_resource"
 */
router.patch(
  '/reports/:id/resolve',
  authenticate,
  requireVerifiedEmail,
  isModerator,
  resolveReport
);

/**
 * @openapi
 * /api/v1/admin/resources/{id}:
 *   delete:
 *     summary: Archive a resource (Moderator/Admin/SuperAdmin)
 *     description: Reject and archive a resource by ID.
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Resource deleted.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Resource rejected and archived"
 */
router.get('/resources/stats', authenticate, requireVerifiedEmail, isSuperAdmin, getResourceStats);
router.get('/resources/approved', authenticate, requireVerifiedEmail, isModerator, listApprovedResources);
router.get('/resources/archived', authenticate, requireVerifiedEmail, isModerator, listArchivedResources);
router.patch('/resources/:id/unarchive', authenticate, requireVerifiedEmail, isModerator, unarchiveResource);
router.delete('/resources/:id', authenticate, requireVerifiedEmail, isModerator, deleteResource);

/**
 * @openapi
 * /api/v1/admin/resources/pending:
 *   get:
 *     summary: List resources pending moderation (Moderator/Admin/SuperAdmin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [Notes, QP]
 *     responses:
 *       200:
 *         description: List of pending resources.
 */
router.get(
  '/resources/pending',
  authenticate,
  requireVerifiedEmail,
  isModerator,
  listPendingResources
);

/**
 * @openapi
 * /api/v1/admin/resources/{id}/approve:
 *   patch:
 *     summary: Approve a pending resource (Moderator/Admin/SuperAdmin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Resource approved.
 */
router.patch(
  '/resources/:id/approve',
  authenticate,
  requireVerifiedEmail,
  isModerator,
  approveResource
);

/**
 * @openapi
 * /api/v1/admin/resources/{id}/reject:
 *   patch:
 *     summary: Reject and archive a pending resource (Moderator/Admin/SuperAdmin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *         appCheck: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *                 example: "Spam upload"
 *     responses:
 *       200:
 *         description: Resource rejected and archived.
 */
router.patch(
  '/resources/:id/reject',
  authenticate,
  requireVerifiedEmail,
  isModerator,
  rejectResource
);

router.get('/cms', authenticate, requireVerifiedEmail, isModerator, getCmsContent);
router.put('/cms/:key', authenticate, requireVerifiedEmail, isSuperAdmin, updateCmsContent);

export default router;
