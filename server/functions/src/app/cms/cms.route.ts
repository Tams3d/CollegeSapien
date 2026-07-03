import { Router } from 'express';
import { getPublicCmsContent } from './cms.controller';

const router = Router();

router.get('/', getPublicCmsContent);

export default router;
