import * as admin from 'firebase-admin';

const firestore = () => admin.firestore();

type ModerationUser = {
  role?: string;
  collegeId?: string;
};

export const getModeratorScopeError = (
  user: ModerationUser | undefined,
  targetCollegeId: string | null | undefined,
  entity: 'Resource' | 'Report'
): string | null => {
  if (user?.role !== 'moderator') return null;

  const moderatorCollegeId =
    typeof user.collegeId === 'string' && user.collegeId.trim().length > 0 ? user.collegeId : null;

  if (!moderatorCollegeId) {
    return 'Forbidden: Moderator is not assigned to a college';
  }

  if (!targetCollegeId || targetCollegeId !== moderatorCollegeId) {
    return `Forbidden: ${entity} belongs to another college`;
  }

  return null;
};

export const archiveResourceForModeration = async (
  resourceRef: admin.firestore.DocumentReference,
  actorUid: string,
  reason: string | null
) => {
  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  await resourceRef.update({
    status: 'rejected',
    rejectedBy: actorUid,
    rejectedReason: reason,
    rejectedAt: timestamp,
    deletedAt: timestamp,
    deletedBy: actorUid,
    updatedAt: timestamp,
  });
};

export const resolvePendingReportsForResource = async (
  resourceId: string,
  actorUid: string,
  resolutionAction: 'delete_resource' | 'ban_user'
) => {
  const pendingReports = await firestore()
    .collection('reports')
    .where('resourceId', '==', resourceId)
    .where('status', '==', 'pending')
    .get();

  if (pendingReports.empty) return 0;

  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  const batch = firestore().batch();

  pendingReports.docs.forEach(reportDoc => {
    batch.update(reportDoc.ref, {
      status: 'resolved',
      resolutionAction,
      resolvedBy: actorUid,
      resolvedAt: timestamp,
      updatedAt: timestamp,
    });
  });

  await batch.commit();
  return pendingReports.size;
};
