import { NextResponse } from 'next/server';
import { listTestimonials } from '@/lib/db/reviews';

const SYSTEM_USER_ID = 'system';

export async function GET() {
  try {
    const result = await listTestimonials(SYSTEM_USER_ID, 10);

    if (!result.success || !result.data) {
      console.error('Failed to fetch testimonials:', result.error);
      return NextResponse.json([]);
    }

    // Transform to public format (only safe fields)
    const testimonials = result.data.items.map((t) => ({
      id: t.id,
      name: t.name,
      storeName: t.storeName,
      rating: t.rating,
      comment: t.comment,
    }));

    const response = NextResponse.json(testimonials);
    // Cache for 1 hour, allow stale for 24 hours while revalidating
    response.headers.set('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
    return response;
  } catch (error) {
    console.error('Failed to fetch testimonials:', error);
    return NextResponse.json([]);
  }
}
