import path from 'path';
import fs from 'fs-extra';
import solc from 'solc';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const buildPath = path.resolve(__dirname, '../build');
fs.removeSync(buildPath);

const willPath = path.resolve(__dirname, '../contracts/WillContract.sol');
const willSource = fs.readFileSync(willPath, 'utf8');
const input = {
    language: 'Solidity',
    sources: {
        'WillContract.sol': {
            content: willSource,
        },
    },
    settings: {
        outputSelection: {
            '*': {
                '*': ['*'],
            },
        },
    },
};
const outputFile= JSON.parse(solc.compile(JSON.stringify(input)));

fs.ensureDirSync(buildPath);
for (let contract in outputFile.contracts['WillContract.sol']) {
    fs.outputJsonSync(
        path.resolve(buildPath, `${contract}.json`),
        outputFile.contracts['WillContract.sol'][contract]
    )
}

console.log('Build complete');