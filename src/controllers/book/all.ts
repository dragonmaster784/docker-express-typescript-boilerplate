import { RequestHandler } from 'express';
import * as cProcess from 'child_process';
import requestMiddleware from '../../middleware/request-middleware';
import Book from '../../models/Book';
import logger from '../../logger';

// deepcode ignore NoRateLimitingForExpensiveWebOperation:
const all: RequestHandler = async (req, res) => {
  const books = await Book.find();

  let data = 'ii';
  const { bookId } = req.params;
  logger.silly(`Book to get: ${bookId}`);

  const { spawn } = cProcess;
  const child = spawn('python3', ['./scripts/python/stitch.py']);
  child.stdin.write('Yeayeayeayea');
  child.stdin.end();
  child.stdout.on('data', (pydat: any) => {
    logger.silly('its a workOUT! ', pydat);
  });
  child.stderr.on('data', (e: any) => {
    logger.info('error: \n', e.toString());
  });
  // eslint-disable-next-line no-restricted-syntax
  for await (const dat of child.stdout) {
    data += dat;
  };

  res.send({ books, log: data });
};

export default requestMiddleware(all);
