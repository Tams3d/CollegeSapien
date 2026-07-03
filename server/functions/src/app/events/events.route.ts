import { Router } from 'express';
import {
  getApprovedEvents,
  createEvent,
  getPendingEvents,
  approveEvent,
  rejectEvent,
} from './events.controller';
import { authenticate, requireVerifiedEmail } from '../../shared/middlewares/auth.middleware';
import { isModerator } from '../../shared/middlewares/role.middleware';

const router = Router();

// Public / Authenticated endpoints for regular users
router.get('/', authenticate, requireVerifiedEmail, getApprovedEvents);
router.post('/', authenticate, requireVerifiedEmail, createEvent);

// Moderator / Admin endpoints
router.get('/pending', authenticate, requireVerifiedEmail, isModerator, getPendingEvents);
router.patch('/:id/approve', authenticate, requireVerifiedEmail, isModerator, approveEvent);
router.patch('/:id/reject', authenticate, requireVerifiedEmail, isModerator, rejectEvent);

export default router;
