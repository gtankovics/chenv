#! /usr/bin/env node

import { $ } from "zx";

const output = (await($`ls`)).stdout;

console.log(output);

