import { Request } from 'express';
import cheerio from 'cheerio';
import { AxiosResponse } from 'axios';
import { IStreamSources } from '@/types';

/**
 * Scrape stream sources asynchronously
 * @param {Request} ExpressRequest
 * @param {AxiosResponse} AxiosResponse
 * @returns {Promise.<IStreamSources[]>} array of stream sources objects
 */
export const scrapeStreamSources = async (
    req: Request,
    res: AxiosResponse
): Promise<IStreamSources[]> => {
    const $: cheerio.Root = cheerio.load(res.data);
    const payload: IStreamSources[] = [];

    // New structure: ul#player-list > li > a with data-server and href
    $('ul#player-list > li > a')
        .each((i, el) => {
            const obj = {} as IStreamSources;

            obj['provider'] =
                $(el).attr('data-server') || $(el).text().trim();
            obj['url'] = $(el).attr('href') || $(el).attr('data-url') || '';
            obj['resolutions'] = [];

            payload.push(obj);
        });

    // Fallback to old structure if player-list not present
    if (payload.length === 0) {
        $('div#load-sources ul > li')
            .each((i, el) => {
                const obj = {} as IStreamSources;
                const resolutions: string[] = [];

                $(el)
                    .find('div > span')
                    .each((i2, el2) => {
                        resolutions.push($(el2).text());
                    });

                obj['provider'] = $(el).find('a').text();
                obj['url'] = $(el).find('a').attr('href') ?? '';
                obj['resolutions'] = resolutions;

                payload.push(obj);
            });
    }

    return payload;
};
