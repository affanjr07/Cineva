import { Request } from 'express';
import cheerio from 'cheerio';
import { AxiosResponse } from 'axios';
import { IMovies, IMovieDetails } from '@/types';

/**
 * Extract movie id from a href like "/mutiny-2026" or "/mutiny-2026/"
 */
const extractId = (href: string | undefined): string => {
    if (!href) return '';
    return href.replace(/\/+$/, '').split('/').pop() ?? '';
};

/**
 * Scrape movies asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<IMovies[]>} array of movies objects
 */
export const scrapeMovies = async (
    req: Request,
    res: AxiosResponse
): Promise<IMovies[]> => {
    const $: cheerio.Root = cheerio.load(res.data);
    const payload: IMovies[] = [];
    const {
        protocol,
        headers: { host },
    } = req;

    $('main.content article, div.gallery-grid article, main article, article')
        .each((i, el) => {
            const anchor = $(el).find('figure > a').first();
            const poster = $(el).find('figure a picture img, figure a img').first();
            const fig = $(el).find('figure');

            const movieId: string = extractId(anchor.attr('href'));

            if (!movieId) return;

            const obj = {} as IMovies;

            obj['_id'] = movieId;
            obj['title'] = poster.attr('alt') ?? $(el).find('h3').text().trim() ?? '';
            obj['type'] = 'movie';

            let posterSrc = poster.attr('src');
            if (!posterSrc) posterSrc = poster.attr('data-src');
            if (posterSrc && !posterSrc.startsWith('http')) {
                posterSrc = `https:${posterSrc}`;
            }
            obj['posterImg'] = posterSrc ?? '';

            obj['rating'] =
                $(fig).find('span.ratingValue, span.rating .ratingValue, span.rating').text().trim() ??
                '';
            obj['url'] = `${protocol}://${host}/movies/${movieId}`;

            obj['qualityResolution'] =
                $(fig).find('span.label, span.label-HD, span.quality').first().text().trim() ?? '';

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
 * Scrape movie details asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<IMovieDetails>} movie details object
 */
export const scrapeMovieDetails = async (
    req: Request,
    res: AxiosResponse
): Promise<IMovieDetails> => {
    const originalUrl = req.path;

    const $: cheerio.Root = cheerio.load(res.data);
    const obj = {} as IMovieDetails;

    const genres: string[] = [];
    const directors: string[] = [];
    const countries: string[] = [];
    const casts: string[] = [];

    obj['_id'] = extractId(originalUrl);

    obj['title'] =
        $('div.movie-info h1').first().text().trim() ||
        $('h1').first().text().trim();

    obj['type'] = 'movie';

    // Watch-history metadata (authoritative source for poster/rating/year/runtime)
    let wh: { poster?: string; rating?: string; year?: number | string; runtime?: string } | null =
        null;
    const whMatch = res.data.match(
        /<script id="watch-history-data" type="application\/json">([\s\S]*?)<\/script>/
    );
    if (whMatch) {
        try {
            wh = JSON.parse(whMatch[1]);
        } catch {
            wh = null;
        }
    }

    let posterImg =
        $('div.poster-area figure a picture img, div.poster-area img, div.content-poster figure picture img, figure a picture img')
            .first()
            .attr('src');
    if (!posterImg) posterImg = $('img[itemprop="image"]').first().attr('data-src');
    if (!posterImg) posterImg = wh?.poster;
    obj['posterImg'] = posterImg && !posterImg.startsWith('http') ? `https:${posterImg}` : (posterImg ?? '');

    obj['rating'] =
        $('span.rating-number').attr('data-base-rating') ||
        $('span.rating-number').first().text().trim() ||
        $('.rating-score .rating-number').first().text().trim() ||
        (wh?.rating ? String(wh.rating) : '');

    if (wh?.runtime) {
        const m = /(\d+):(\d+)/.exec(wh.runtime);
        if (m) obj['duration'] = `${Number(m[1])}h ${Number(m[2])}m`;
    }
    if (wh?.year && !obj['releaseDate']) {
        obj['releaseDate'] = String(wh.year);
    }

    // Quality & duration from info-tag spans
    const infoTags: string[] = [];
    $('div.info-tag > span').each((i, el) => {
        infoTags.push($(el).text().trim());
    });
    obj['quality'] = infoTags.find((t) => /(bluray|webdl|web-?dl|hdcam|hdrip|hdtv)/i.test(t)) ?? '';
    obj['duration'] = infoTags.find((t) => /(\dh|\d+m|min)/i.test(t)) ?? '';

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

    // If countries empty, fall back to info-meta (movies)
    if (countries.length === 0) {
        $('div.movie-info div.tag-list span.tag > a').each((i, el) => {
            const href = $(el).attr('href') ?? '';
            if (href.includes('/country/')) countries.push($(el).text().trim());
        });
    }

    // Synopsis
    obj['synopsis'] =
        $('div.synopsis.collapsed').first().text().trim() ||
        $('div.synopsis').first().text().trim();

    // Trailer (yt-lightbox link)
    obj['trailerUrl'] = $('a.yt-lightbox').first().attr('href') ?? '';

    obj['genres'] = genres;
    obj['directors'] = directors;
    obj['countries'] = countries;
    obj['casts'] = casts;

    return obj;
};
