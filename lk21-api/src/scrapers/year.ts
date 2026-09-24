import cheerio from 'cheerio';
import { AxiosResponse } from 'axios';
import { Request } from 'express';
import { ISetOfYears } from '@/types';

/**
 * Scrape a set of release years asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<ISetOfYears[]>} a set of release years
 */
export const scrapeSetOfYears = async (
    req: Request,
    res: AxiosResponse
): Promise<ISetOfYears[]> => {
    const $: cheerio.Root = cheerio.load(res.data);
    const payload: ISetOfYears[] = [];
    const {
        protocol,
        headers: { host },
    } = req;

    $('select[name="tahun"] > option, select[name="year"] > option').each(
        (i, el) => {
            const parameter = $(el).attr('value');
            const text = $(el).text().trim();

            if (!parameter || parameter === '' || parameter === '0') return;
            if (!/^\d{4}$/.test(parameter) && !/^\d{4}$/.test(text)) return;

            const year = /^\d{4}$/.test(parameter) ? parameter : text;

            payload.push({
                parameter: year,
                numberOfContents: 0,
                url: `${protocol}://${host}/years/${year}`,
            });
        }
    );

    // Fallback: footer year links
    if (payload.length === 0) {
        const seen = new Set<string>();
        $('a[href^="/year/"]').each((i, el) => {
            const href = $(el).attr('href') ?? '';
            const year = href.replace('/year/', '').split('/')[0];
            if (!/^\d{4}$/.test(year) || seen.has(year)) return;
            seen.add(year);
            payload.push({
                parameter: year,
                numberOfContents: 0,
                url: `${protocol}://${host}/years/${year}`,
            });
        });
    }

    return payload;
};
