import cheerio from 'cheerio';
import { AxiosResponse } from 'axios';
import { Request } from 'express';
import { ISetOfGenres } from '@/types';

/**
 * Scrape a set of genres asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<ISetOfGenres[]>} a set of genres
 */
export const scrapeSetOfGenres = async (
    req: Request,
    res: AxiosResponse
): Promise<ISetOfGenres[]> => {
    const $: cheerio.Root = cheerio.load(res.data);
    const payload: ISetOfGenres[] = [];
    const {
        headers: { host },
        protocol,
    } = req;

    const seen = new Set<string>();

    $('select[name="genre1"] > option, select[name="genre2"] > option')
        .each((i, el) => {
            const parameter = $(el).attr('value');
            const name = $(el).text().trim();

            if (!parameter || parameter === '' || seen.has(parameter)) return;
            seen.add(parameter);

            payload.push({
                parameter,
                name,
                numberOfContents: 0,
                url: `${protocol}://${host}/genres/${parameter}`,
            });
        });

    return payload;
};
