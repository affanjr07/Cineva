import axios from '@/axios';
import { NextFunction as Next, Request, Response } from 'express';
import { scrapeSearchedMoviesOrSeries } from '@/scrapers/search';

type TController = (req: Request, res: Response, next?: Next) => Promise<void>;

/**
 * Controller for /search/:title` route
 *
 * LK21 search is rendered client-side: the search page (`/search?s=`)
 * loads results via AJAX from `search.php` on the host stored in the
 * `<body data-search_url="...">` attribute. We read that host (falling
 * back to the known `gudangvape.com` base), call `search.php?s=...&page=...`
 * and parse the returned JSON.
 *
 * @param {Request} req
 * @param {Response} res
 * @param {Next} next
 */
export const searchedMoviesOrSeries: TController = async (req, res) => {
    try {
        const { title = '' } = req.params;
        const { page = 0 } = req.query;

        const params = new URLSearchParams({
            s: title,
            page: String((Number(page) || 0) + 1),
        });

        const axiosRequest = await axios.get(
            `${process.env.LK21_URL}/search?s=${title}`
        );

        const searchUrl =
            extractBodyAttr(axiosRequest.data, 'data-search_url') ||
            'https://gudangvape.com/';
        const thumbnailUrl =
            extractBodyAttr(axiosRequest.data, 'data-thumbnail_url') ||
            'https://poster.assetsy.de/wp-content/uploads/';

        const searchRes = await axios.get(
            `${searchUrl.replace(/\/+$/, '')}/search.php?${params.toString()}`,
            {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    Referer:
                        process.env.LK21_REFERER ||
                        'https://tv12.lk21official.cc/',
                },
            }
        );

        const payload = scrapeSearchedMoviesOrSeries(
            req,
            searchRes,
            thumbnailUrl
        );

        res.status(200).json(payload);
    } catch (err) {
        console.error(err);

        res.status(400).json(null);
    }
};

function extractBodyAttr(html: string, attr: string): string {
    const m = html.match(new RegExp(`<body[^>]*${attr}\\s*=\\s*['"]([^'"]*)['"]`));
    return m?.[1] ?? '';
}
