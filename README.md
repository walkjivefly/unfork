unfork.sh
=========

A little script to (attempt) to unfork (get off) a forked blockchain

## Usage:
unfork.sh [fix]

If run without the "fix" option the script will simply produce a
sitrep comparing this node's position with the explorer.
The fix option will cause it to attempt to resolve a fork if one is
detected.

## Method:
- check if we actually forked, and if so:
- use binary chop to find the fork height
- invalidateblock the fork point
- shutdown the daemon
- remove peers.dat
- start the daemon

## Requirements:
- an explorer which provides getblockcount and getblockhash functions
(an Iquidus explorer is ideal, Cryptoid is also known to work)

## Donations:
If you find it useful, feel free to sling some crypto my way!
- BTC: 35A8NHSFKIJAPGPDUGPOXC6TFCUHYYXVUP
- LTC: MVMU2YikpetyFB4mUKt9rSzhUQhw87hjgV
- CRW: CRWFdMDPdi5uuzBZRi9kBi8pfDCbP6ZE2kYG
- BLOCK: BX1SJMYmthjj3R6emV2LJgR3ZCMokJR1cx

## MIT License
Copyright (c) 2019, Mark Brooker <mark@walkjivefly.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
