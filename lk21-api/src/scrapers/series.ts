import cheerio from 'cheerio';
import { AxiosResponse } from 'axios';
import { Request } from 'express';
import { ISeasonsList, ISeries, ISeriesDetails } from '@/types';

/**
 * Extract id from a href like "/stuart-fails-save-universe-2026"
 */
const extractId = (href: string | undefined): string => {
    if (!href) return '';
    return href.replace(/\/+$/, '').split('/').pop() ?? '';
};

/**
 * Scrape series asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<ISeries[]>} array of series objects
 */
export const scrapeSeries = async (
    req: Request,
    res: AxiosResponse
): Promise<ISeries[]> => {
    const $: cheerio.Root = cheerio.load(res.data);
    const payload: ISeries[] = [];
    const {
        headers: { host },
        protocol,
    } = req;

    $('main article, div.gallery-grid article, article')
        .each((i, el) => {
            const anchor = $(el).find('figure > a').first();
            const poster = $(el).find('figure a picture img, figure a img').first();
            const fig = $(el).find('figure');

            const seriesId: string = extractId(anchor.attr('href'));
            if (!seriesId) return;

            const obj = {} as ISeries;

            obj['_id'] = seriesId;
            obj['title'] =
                poster.attr('alt') || $(el).find('h3').text().trim() || '';
            obj['type'] = 'series';

            let posterSrc = poster.attr('src') || poster.attr('data-src') || '';
            if (posterSrc && !posterSrc.startsWith('http')) {
                posterSrc = `https:${posterSrc}`;
            }
            obj['posterImg'] = posterSrc;

            obj['episode'] = Number(
                $(fig).find('span.episode strong').first().text().trim()
            );
            obj['rating'] =
                $(fig)
                    .find(
                        'span[itemprop="ratingValue"], span.ratingValue, span.rating .ratingValue, span.rating'
                    )
                    .first()
                    .text()
                    .trim() || '';
            obj['url'] = `${protocol}://${host}/series/${seriesId}`;

            const genres: string[] = [];
            $(el)
                .find('div.genre a, meta[itemprop="genre"]')
                .each((i2, el2) => {
                    const href = $(el2).attr('href') ?? '';
                    if (href.includes('/genre/')) {
                        const g = href.split('/genre/')[1]?.split('/')[0];
                        if (g) genres.push(g);
                    } else {
                        const content = $(el2).attr('content');
                        if (content) {
                            content.split(',').forEach((c) => {
                                const gc = c.trim().toLowerCase().replace(/\s+/g, '-');
                                if (gc) genres.push(gc);
                            });
                        }
                    }
                });
            obj['genres'] = genres;

            payload.push(obj);
        });

    return payload;
};

/**
 * Scrape series details asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<ISeriesDetails>} series details object
 */
export const scrapeSeriesDetails = async (
    req: Request,
    res: AxiosResponse
): Promise<ISeriesDetails> => {
    const originalUrl = req.path;

    const $: cheerio.Root = cheerio.load(res.data);
    const obj = {} as ISeriesDetails;

    const genres: string[] = [];
    const directors: string[] = [];
    const countries: string[] = [];
    const casts: string[] = [];

    obj['_id'] = extractId(originalUrl);

    obj['title'] =
        $('div.movie-info h1').first().text().trim() ||
        $('h1').first().text().trim();
    obj['type'] = 'series';

    const posterImg =
        $('div.poster-area figure a picture img, div.poster-area img, div.content-poster figure picture img, figure a picture img')
            .first()
            .attr('src') ||
        $('img[itemprop="image"]').first().attr('data-src') ||
        '';

    // Watch history metadata (authoritative source for poster/rating/episode count)
    const whMatch = res.data.match(
        /<script id="watch-history-data" type="application\/json">([\s\S]*?)<\/script>/
    );
    let wh: { poster?: string; rating?: string; total_eps?: number; year?: number | string; title?: string } | null = null;
    if (whMatch) {
        try {
            wh = JSON.parse(whMatch[1]);
        } catch {
            wh = null;
        }
    }

    const posterSrc = posterImg || wh?.poster || '';
    obj['posterImg'] = posterSrc && !posterSrc.startsWith('http') ? `https:${posterSrc}` : posterSrc;

    obj['rating'] =
        $('span.rating-number').attr('data-base-rating') ||
        $('span.rating-number').first().text().trim() ||
        (wh?.rating ? String(wh.rating) : '');

    if (wh?.year && !obj['releaseDate']) {
        obj['releaseDate'] = String(wh.year);
    }

    // Synopsis
    obj['synopsis'] =
        $('div.synopsis.collapsed').first().text().trim() ||
        $('div.synopsis').first().text().trim();

    // Quality & duration from info-tag spans
    const infoTags: string[] = [];
    $('div.info-tag > span').each((i, el) => {
        infoTags.push($(el).text().trim());
    });
    obj['duration'] = infoTags.find((t) => /(\dh|\d+m|min|S\.)/i.test(t)) ?? '';

    // Genres & countries from tag-list
    $('div.tag-list span.tag > a').each((i, el) => {
        const href = $(el).attr('href') ?? '';
        const text = $(el).text().trim();
        if (href.includes('/genre/')) genres.push(text);
        if (href.includes('/country/')) countries.push(text);
    });

    // Meta detail block
    $('div.detail.hidden > p, div.detail > p').each((i, el) => {
        const label = $(el).find('span').text().toLowerCase().replace(':', '').trim();
        const values = $(el)
            .find('a')
            .map((i2, el2) => $(el2).text().trim())
            .get();

        switch (label) {
            case 'sutradara':
                directors.push(...values);
                break;
            case 'bintang film':
            case 'bintang':
                casts.push(...values);
                break;
            case 'negara':
                countries.push(...values);
                break;
            case 'release':
                obj['releaseDate'] = $(el).text().replace(label, '').replace(':', '').trim();
                break;
            default:
                break;
        }
    });

    // Trailer (youtube iframe)
    obj['trailerUrl'] =
        $('div.trailer-series iframe').attr('src') ||
        $('div.player-content iframe').attr('src') ||
        $('a.yt-lightbox').first().attr('href') ||
        '';

    // Status
    obj['status'] = $('div.movie-info span.badge, span.badge, div.info-tag span')
        .filter((i, el) => /ongoing|completed|tamat|berlangsung|hiatus/i.test($(el).text()))
        .first()
        .text()
        .toLowerCase()
        .trim() || 'ongoing';

    // Seasons & episodes from season-data JSON
    const seasons: ISeasonsList[] = [];
    const sdMatch = res.data.match(
        /<script id="season-data" type="application\/json">([\s\S]*?)<\/script>/
    );
    if (sdMatch) {
        try {
            const data = JSON.parse(sdMatch[1]);
            Object.keys(data).forEach((seasonKey) => {
                const eps = Array.isArray(data[seasonKey]) ? data[seasonKey] : [];
                seasons.push({
                    season: Number(seasonKey),
                    totalEpisodes: eps.length,
                });
            });
        } catch {
            /* ignore */
        }
    }

    // Total recorded episodes from watch-history (avoids related-series false positives)
    if (typeof wh?.total_eps === 'number' && wh.total_eps > 0) {
        obj['episode'] = wh.total_eps;
    } else {
        obj['episode'] = seasons.reduce((acc, s) => acc + s.totalEpisodes, 0);
    }

    obj['genres'] = genres;
    obj['directors'] = directors;
    obj['countries'] = countries;
    obj['casts'] = casts;
    obj['seasons'] = seasons;

    return obj;
};
