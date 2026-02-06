import { NextRequest, NextResponse } from 'next/server';
import { getPendingJobs, lockJob, completeJob, failJob } from '@/lib/db/audit-jobs';
import { updateAudit } from '@/lib/db/audits';

export const runtime = 'nodejs';
export const maxDuration = 300;
export const dynamic = 'force-dynamic';

const SYSTEM_USER_ID = 'system';

// Verify cron secret to prevent unauthorized access
function verifyCronSecret(req: NextRequest): boolean {
  const cronSecret = process.env.CRON_SECRET;
  if (!cronSecret) {
    // If no secret configured, allow in development
    return process.env.NODE_ENV === 'development';
  }

  const authHeader = req.headers.get('authorization');
  return authHeader === `Bearer ${cronSecret}`;
}

export async function GET(req: NextRequest) {
  if (!verifyCronSecret(req)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const result = await getPendingJobs(SYSTEM_USER_ID, 5, 10);

    if (!result.success || !result.data) {
      return NextResponse.json({ error: result.error }, { status: 500 });
    }

    const jobs = result.data.items;
    const processed: string[] = [];
    const failed: string[] = [];

    for (const job of jobs) {
      // Try to lock the job
      const lockResult = await lockJob(SYSTEM_USER_ID, job.id);
      if (!lockResult.success || !lockResult.data?.locked) {
        continue; // Another worker got it
      }

      try {
        // Update audit status to processing
        await updateAudit(SYSTEM_USER_ID, job.auditId, {
          status: 'CRAWLING',
        });

        // TODO: Implement actual crawling and analysis here
        // For now, we'll just simulate the process

        // This is where you'd call:
        // 1. Crawl the store pages
        // 2. Analyze with AI
        // 3. Generate fixes
        // 4. Update audit with results

        // Mark job as complete
        await completeJob(SYSTEM_USER_ID, job.id);
        processed.push(job.auditId);

      } catch (error) {
        console.error(`Job ${job.id} failed:`, error);
        await failJob(
          SYSTEM_USER_ID,
          job.id,
          error instanceof Error ? error.message : 'Unknown error'
        );
        failed.push(job.auditId);
      }
    }

    return NextResponse.json({
      processed: processed.length,
      failed: failed.length,
      processedAudits: processed,
      failedAudits: failed,
    });
  } catch (error) {
    console.error('Cron job error:', error);
    return NextResponse.json(
      { error: 'Failed to process jobs' },
      { status: 500 }
    );
  }
}
