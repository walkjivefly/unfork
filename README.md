unfork.sh
=========

A little script to (attempt) to unfork (get off) a forked blockchain.
It was designed to be used with the Crown blockchain on your VPS or 
with a linux wallet. There are now customised versions for several different
coins which you might run on a Blocknet servicenode. 

It does two things:

* Checks whether your node/wallet is on the same chain as the explorer.
* Optionally executes the appropriate commands to get you back on the same chain as the explorer.

The script assumes that the explorer is on the correct chain. 
If you suspect you are forked, and the script says you are, then you should 
check if the explorer is believed to be on the correct chain before letting 
it (attempt to) fix the problem. Ask in your coin's Discord or Telegram or
other chat channels. If the consensus is that the explorer is on the correct 
chain then:
* Remove any existing `addnode=` lines from your coin config, eg: `crown.conf`
* Add some `addnode=` entries to your coin config for nodes known to be on the correct chain. You can probably get this list from the coin explorer. If your explorer doesn't have this feature then ask in your coin's Discord or Telegram or other chat channels for some suitable node addresses.
* Re-run the script with the fix option and let it work its magic.

# Download and install
These instructions are based on using the script to fix a Crown wallet or node. Mentally replace `Crown` by the name of your coin and you should be good to go.

Sign on to your VPS with the userid you use to run your masternode or 
systemnode.

Enter
```
sudo curl -o /usr/local/bin/unfork.sh https://raw.githubusercontent.com/walkjivefly/unfork/master/unfork-xxx.sh
sudo chmod +x /usr/local/bin/unfork.sh
```
Replace `xxx` by the lowercase symbol for your coin. If you login as root you don’t need to use the sudo prefix.

You can also use the script on your linux wallet machine. 
If you normally run the QT wallet you’ll need to shut it down and run 
the daemon wallet instead.

# Customise
If your datadir is not called .crown and located in the logged in 
user’s home directory then you need to customise the script.

Use vi or nano or your favourite editor to customise the values for 
CONFIG and DATADIR.

Additionally, if you choose not to install the script in /usr/local/bin, 
customise the PREFIX variable with the appropriate value.

## Run manually
At any time simply enter:
```
unfork.sh
```
to get a current sit rep. If the script indicates you're forked and you 
believe the explorer is on the correct chain, you can re-run it with the
_fix_ option
```
unfork.sh fix
```
to have it attempt to resolve the fork without you having to resync the
entire blockchain.

### Unforked example
These examples demonstrate use with the Crown blockchain. The script
includes sample customisations for Crown (CRW) and for Blocknet (BLOCK).
```
mark@x230:~$ unfork.sh
unfork.sh checking crown blockchain for forks at Wed 29 May 14:03:04 +07 2019

Our latest block is 2392389
Latest block at the explorer is 2392389

We are level with the explorer
and on the same chain. Nothing to do here!
```
### Forked example
```
crown@Crown-Testnet:~$ unfork.sh
unfork.sh checking crown blockchain for forks at Wed May 29 14:59:55 UTC 2019

Our latest block is 2392775
Latest block at the explorer is 2392846

We are behind the explorer
Searching for the fork point...
Forked at 2392775
Our hash is 4759b0b107552c7c70d28910c1a4bae3c4fe89d6532e85d0b5241c1968ba19e0
Explorer has 58efb6cb2972ee48fe1a036e1de68989ca82ec4d0953b6d6fab91710ba3981ff

Run with unfork.sh fix to actually fix the fork
```
Here, the script has detected the node is behind the explorer and not on 
the same chain. It used a binary chop method to identify the fork point 
and then reported the situation to the user.

### Forked example with fix option
If you’re running the script on your wallet machine rather than a node VPS, 
it is good practice to make a backup of your wallet.dat before proceeding 
further.

Then re-run the script with the fix option for it to attempt to resolve the 
problem without having to resync from scratch.
```
crown@Crown-Testnet:~$ unfork.sh fix
unfork.sh checking crown blockchain for forks at Wed May 29 15:02:57 UTC 2019

Our latest block is 2392775
Latest block at the explorer is 2392850

We are behind the explorer
Searching for the fork point...
Forked at 2392775
Our hash is 4759b0b107552c7c70d28910c1a4bae3c4fe89d6532e85d0b5241c1968ba19e0
Explorer has 58efb6cb2972ee48fe1a036e1de68989ca82ec4d0953b6d6fab91710ba3981ff

Invalidating the fork point

Shutting down the daemon
Crown server stopping
...waiting...

Re-starting the daemon
Crown server starting

Use the command
  crown-cli getblockcount
to monitor the chain and make sure the daemon is resyncing.
You have at least 76 blocks to catch up.

crown@Crown-Testnet:~$ crown-cli getblockcount
error: {"code":-28,"message":"Loading block index..."}

crown@Crown-Testnet:~$ crown-cli getblockcount
2392852
```
You can see the first attempt after restarting at a getblockcount failed 
with an error message because the daemon was busy reloading the block index. 

A few seconds later the retried command worked and the daemon had caught 
up with the explorer.

# Automated execution
You could create a crontab entry to run the script automatically but doing 
so isn’t really recommended. The reason it’s not recommended is that the 
explorer is not an Oracle; it’s just as likely to be on a forked chain as 
anyone else.


# Requirements
- an explorer which provides getblockcount and getblockhash functions 
(an Iquidus explorer is ideal, Cryptoid is also known to work)

# Donations
If you find it useful, feel free to sling some crypto my way!
-   BTC: 36TBpGyBaNm4UpETLuvs7RHNfoiAuz7mxD
-   LTC: MVMU2YikpetyFB4mUKt9rSzhUQhw87hjgV
-   CRW: CRWFdMDPdi5uuzBZRi9kBi8pfDCbP6ZE2kYG
- BLOCK: BVbpLYh8kCq8vXxLAa726azu3EZfXFkjRh

# MIT License
Copyright (c) 2019-2021, Mark Brooker <mark@walkjivefly.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
