import { AxiosResponse } from 'axios';
import { Request } from 'express';
import { ISearchedMoviesOrSeries } from '@/types';

/**
 * Parse the JSON returned by LK21's AJAX search endpoint (`search.php`).
 *
 * Example payload item:
 * {
 *   "episode": "", "id": "...", "is_complete": 0,
 *   "poster": "2026/08/film-...jpg", "quality": "CAM", "rating": 7.9,
 *   "runtime": "02:25", "season": "", "slug": "spider-man-...-2026",
 *   "title": "Spider-Man: Brand New Day (2026)", "type": "movie", "year": 2026
 * }
 *
 * @param {Request} req
 * @param {AxiosResponse} res
 * @param {string} thumbnailBase base URL for relative poster paths
 * @returns {Promise.<ISearchedMoviesOrSeries[]>}
 */
export const scrapeSearchedMoviesOrSeries = (
    req: Request,
    res: AxiosResponse,
    thumbnailBase: string
): ISearchedMoviesOrSeries[] => {
    const {
        headers: { host },
        protocol,
    } = req;

    const body = res.data;
    const items: any[] =
        (body && (body.data || body.items)) && Array.isArray(body.data || body.items)
            ? body.data || body.items
            : Array.isArray(body)
              ? body
              : [];

    const payload: ISearchedMoviesOrSeries[] = items
        .map((item) => {
            if (!item || !item.slug) return null;

            const type: 'movie' | 'series' = item.type === 'series' ? 'series' : 'movie';

            let posterSrc = '';
            if (item.poster) {
                posterSrc = item.poster.startsWith('http')
                    ? item.poster
                    : `${thumbnailBase.replace(/\/+$/, '')}/${item.poster.replace(/^\/+/, '')}`;
            }

            return {
                _id: item.slug,
                title: item.title ?? '',
                type,
                posterImg: posterSrc,
                url: `${protocol}://${host}/${type === 'series' ? 'series' : 'movies'}/${item.slug}`,
                genres: [],
                directors: [],
                casts: [],
            } as ISearchedMoviesOrSeries;
        })
        .filter((x): x is ISearchedMoviesOrSeries => x !== null);

    return payload;
};
