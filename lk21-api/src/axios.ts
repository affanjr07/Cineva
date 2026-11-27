import axios from 'axios';
import https from 'https';

const api = axios.create({
    timeout: 20000,
    httpsAgent: new https.Agent({
        rejectUnauthorized: false,
    }),
    headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
});

export default api;

