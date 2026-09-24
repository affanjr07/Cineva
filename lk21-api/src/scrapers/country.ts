import cheerio from 'cheerio';
import { AxiosResponse } from 'axios';
import { Request } from 'express';
import { ISetOfCountries } from '@/types';

/**
 * Scrape a set of countries asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<ISetOfCountries[]>} a set of countries
 */
export const scrapeSetOfCountries = async (
    req: Request,
    res: AxiosResponse
): Promise<ISetOfCountries[]> => {
    const $: cheerio.Root = cheerio.load(res.data);
    const payload: ISetOfCountries[] = [];
    const {
        protocol,
        headers: { host },
    } = req;

    const seen = new Set<string>();

    $('select[name="country"] > option').each((i, el) => {
        const parameter = $(el).attr('value');
        const name = $(el).text().trim();

        if (!parameter || parameter === '' || seen.has(parameter)) return;
        seen.add(parameter);

        payload.push({
            parameter,
            name,
            numberOfContents: 0,
            url: `${protocol}://${host}/countries/${parameter}`,
        });
    });

    // Fallback: countries from footer links
    if (payload.length === 0) {
        $('a[href^="/country/"]').each((i, el) => {
            const href = $(el).attr('href') ?? '';
            const parameter = href.replace('/country/', '').split('/')[0];
            const name = $(el).text().trim();
            if (!parameter || seen.has(parameter)) return;
            seen.add(parameter);
            payload.push({
                parameter,
                name: name || parameter,
                numberOfContents: 0,
                url: `${protocol}://${host}/countries/${parameter}`,
            });
        });
    }

    return payload;
};
