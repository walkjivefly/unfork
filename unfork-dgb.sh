#!/bin/bash
# unfork.sh
#
# A little script to (attempt) to unfork (get off) a forked blockchain
#
# Copyright (c) 2019 Mark Brooker <mark@walkjivefly.com>
# Distributed under the MIT software license, see the accompanying
# file LICENSE or http://www.opensource.org/licenses/MIT
#
# Usage:
#  unfork.sh [fix]
#
#  If run without the "fix" option the script will simply produce a 
#  sitrep comparing this node's position with the explorer.
#  The fix option will cause it to attempt to resolve a fork if one is
#  detected.
# 
# Method:
# - check if we actually forked, if so:
# - use binary chop to find the fork height
# - invalidateblock the fork point
# - shutdown the daemon
# - remove peers.dat
# - start the daemon
#
# Requirements:
# - an explorer which provides getblockcount and getblockhash functions
#   (an Iquidus explorer is ideal, Cryptoid is also known to work)
#
# Donations:
#   If you find it useful, feel free to sling some crypto my way!
#   - BTC: 35A8NHSFKIJAPGPDUGPOXC6TFCUHYYXVUP
#   - LTC: MVMU2YikpetyFB4mUKt9rSzhUQhw87hjgV
#   - CRW: CRWFdMDPdi5uuzBZRi9kBi8pfDCbP6ZE2kYG
#   - BLOCK: BX1SJMYmthjj3R6emV2LJgR3ZCMokJR1cx
#


# Customise these to suit your environment
COIN="digibyte"
DATADIR="$HOME/.digibyte"
CONFIG="$DATADIR/digibyte.conf"
#
EXPLORER="https://chainz.cryptoid.info/dgb/api.dws?q="
#
PREFIX="/usr/local/bin"		# path to executables
#
DAEMON="${COIN}d"
DAEMONCMD="${PREFIX}/${DAEMON} -conf=${CONFIG} -datadir=${DATADIR} "
CLIENT="${COIN}-cli"
CLIENTCMD="${PREFIX}/${CLIENT} -conf=${CONFIG} -datadir=${DATADIR}"

# We do this more than once and it's a friction point so make it a function
get_explorer_hash() {
    CHAINHASH=`curl --silent "${EXPLORER}getblockhash&height=$*" 2>/dev/null`
    # Cryptoid explorer wraps quotes around the hash. Remove them!
    echo ${CHAINHASH//'"'}
}

# Tell the user what's happening (useful if run from cron with redirection)
echo "${0##*/} checking ${COIN} blockchain at $(date)"

# Start off by looking for running daemon.
PID=$(pidof ${DAEMON})

# If it's not running we're done.
if [[ $? -eq 1 ]]; then
  echo "${DAEMON} not running. Please start it and try again"
  exit 4
fi
#echo "${DAEMON} PID is ${PID}"
echo

# Find our current blockheight.
OURHIGH=`${CLIENTCMD} getblockcount`
echo "Our latest block is ${OURHIGH}"
OURHASH=`${CLIENTCMD} getblockhash ${OURHIGH}`
#echo "with blockhash ${OURHASH}"
#echo

# Find the current explorer blockheight.
CHAINHIGH=`curl --silent ${EXPLORER}getblockcount 2>/dev/null`
echo "Latest block at the explorer is ${CHAINHIGH}"
CHAINHASH=$(get_explorer_hash ${CHAINHIGH})
#echo "with blockhash ${CHAINHASH}"
echo

# Give the user a sitrep.
if [[ ${OURHIGH} -gt ${CHAINHIGH} ]]; then
  echo "We are ahead of the explorer"
  OURHASH=`${CLIENTCMD} getblockhash ${CHAINHIGH}`
  if [[ ${OURHASH} == ${CHAINHASH} ]]; then
    echo "but on the same chain. Nothing to do here!"
    exit 0
  fi
  HIGH=${CHAINHIGH}
elif [[ ${OURHIGH} -eq ${CHAINHIGH} ]]; then
  echo "We are level with the explorer"
  if [[ ${OURHASH} == ${CHAINHASH} ]]; then
    echo "and on the same chain. Nothing to do here!"
    exit 0
  fi
  HIGH=${OURHIGH}
else 
  echo "We are behind the explorer"
  CHAINHASH=$(get_explorer_hash ${OURHIGH})
  if [[ ${OURHASH} == ${CHAINHASH} ]]; then
    echo "but on the same chain. Nothing to do here!"
    exit 0
  fi
  HIGH=${OURHIGH}
fi

# We have work to do. Binary chop to find the fork height.
echo
echo "Searching for the fork point..."
LAST=0
LOW=1
while true; do
  BLOCK=$(($((${LOW}+${HIGH}))/2))
  #echo "Low=${LOW} High=${HIGH} Checking ${BLOCK}"
  OURHASH=`${CLIENTCMD} getblockhash ${BLOCK}`
  #echo "Our hash is ${OURHASH}"
  CHAINHASH=$(get_explorer_hash ${BLOCK})
  #echo "Explorer hash is ${CHAINHASH}"
  if [[ ${OURHASH} == ${CHAINHASH} ]]; then
    # go right
    LOW=${BLOCK}
  else
    # go left
    HIGH=${BLOCK}
  fi
  if [[ ${LOW} == ${HIGH} ]]; then	# found it
    break
  elif [[ ${BLOCK} == ${LAST} ]]; then	# nudge
    LOW=${HIGH}
  fi
  LAST=${BLOCK}
done
echo "We forked at ${BLOCK}"
echo "Our hash is ${OURHASH}"
echo "Explorer has ${CHAINHASH}"
echo

if [[ $1 != "fix" ]]; then
  echo "Run with unfork.sh fix to actually fix the fork"
  exit
fi

# Invalidate the block.
echo "Invalidating the fork point"
${CLIENTCMD} invalidateblock ${OURHASH}

# Shutdown.
echo "Shutting down the daemon"
${CLIENTCMD} stop

# Allow up to 10 minutes for it to shutdown gracefully.
for ((i=0; i<60; i++)); do
  echo "...waiting..."
  sleep 10
  if [[ $(ps -p ${PID} | wc -l) -lt 2 ]]; then
     break
  fi
done

# If it still hasn't shutdown, terminate with extreme prejudice.
if [[ ${i} -eq 60 ]]; then
  echo "Shutdown still incomplete, killing the daemon."
  kill -9 ${PID}
  sleep 10
  rm -f ${DATADIR}/${DAEMON}.pid ${DATADIR}/.lock
fi

# Remove peers.dat and restart it. 
rm -f ${DATADIR}/peers.dat
echo "Re-starting the daemon"
${DAEMONCMD} -daemon

echo "Use the command"
echo "  ${CLIENT} getblockcount"
echo "to monitor the chain and make sure the daemon is resyncing."
echo "You have at least $((${CHAINHIGH} - ${BLOCK} + 1)) blocks to catch up."
