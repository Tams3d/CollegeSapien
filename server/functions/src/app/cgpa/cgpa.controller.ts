import { Response } from 'express';
import { AuthRequest } from '../../shared/middlewares/auth.middleware';
import { InternalMarksSchema } from './cgpa.model';
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

export const calculateCGPA = async (req: AuthRequest, res: Response) => {
  try {
    const { imageBase64 } = req.body;
    if (!imageBase64) return res.status(400).json({ error: 'Image data is required' });

    const model = genAI.getGenerativeModel({ model: 'gemini-3.1-pro-preview' });
    const prompt =
      "Parse this grade sheet image and calculate the GPA and CGPA. Return a JSON object with fields 'gpa', 'cgpa', and 'subjects' (array of { name, grade, credits }).";

    const result = await model.generateContent([
      prompt,
      {
        inlineData: {
          data: imageBase64,
          mimeType: 'image/png',
        },
      },
    ]);

    const response = await result.response;
    const text = response.text();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    const resultJson = jsonMatch
      ? JSON.parse(jsonMatch[0])
      : { error: 'Could not parse JSON', raw: text };

    return res.status(200).json(resultJson);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

export const predictExternalMarks = async (req: AuthRequest, res: Response) => {
  try {
    const validated = InternalMarksSchema.parse(req.body);
    const { internalMarks, maxInternalMarks, targetGrade } = validated;

    if (internalMarks > maxInternalMarks) {
      return res.status(400).json({ error: 'Internal marks cannot exceed max internal marks' });
    }

    // Grade to Points (Anna University style example)
    const gradePoints: Record<string, number> = {
      O: 91,
      'A+': 81,
      A: 71,
      'B+': 61,
      B: 51,
    };

    const targetTotal = gradePoints[targetGrade];
    const externalWeightage = 100 - maxInternalMarks;

    // Total needed from external = Target - Internal
    const externalNeeded = targetTotal - internalMarks;

    // Scale external needed to 100 if exam is out of 100.
    // If the exam is out of 100 but weightage is `externalWeightage`,
    // then (marks_obtained / 100) * externalWeightage = externalNeeded.
    // marks_obtained = (externalNeeded / externalWeightage) * 100
    const marksToGetOutOf100 = Math.ceil((externalNeeded / externalWeightage) * 100);

    return res.status(200).json({
      targetGrade,
      internalMarks,
      maxInternalMarks,
      requiredInExternalOutOf100: Math.max(0, marksToGetOutOf100),
      message:
        marksToGetOutOf100 > 100
          ? 'Impossible to reach this grade with current internals, machi!'
          : `You need ${Math.max(0, marksToGetOutOf100)} out of 100 in external to get ${targetGrade}. Semma target!`,
    });
  } catch (error: any) {
    return res.status(400).json({ error: error.message });
  }
};
