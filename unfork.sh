#!/bin/bash
# unfork.sh
#
# A little script to (attempt) to unfork (get off) a forked blockchain
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
# - an explorer which provides getblockcount and getblockhash functions.
#   (an Iquidus explorer is ideal)
#

# Customise these to suit your environment
COIN="crown"
CONFIG="/etc/masternodes/crownsn_n2.conf"	# could be "crown.conf"
CONFIG="crown.conf"
DATADIR="/var/lib/masternodes/crownsn2"		# could be "~/.crown"
DATADIR="~/.crown"
PREFIX="/usr/local/bin"				# path to Crown executables
DAEMON="${COIN}d"
DAEMONCMD="${PREFIX}/${DAEMON} -conf=${CONFIG} -datadir=${DATADIR} "
CLIENT="${COIN}-cli"
CLIENTCMD="${PREFIX}/${CLIENT} -conf=${CONFIG} "
EXPLORER="https://iquidus-01.crown.tech/api"	# explorer API base URL

# Tell the user what's happening (useful if run from cron with redirection)
echo "${0##*/} checking ${COIN} blockchain for forks at $(date)"

# Start off by looking for running daemon.
PID=$(pidof ${DAEMON})

# If it's not running we're done.
if [[ $? -eq 1 ]]; then
  echo "${DAEMON} not running. Please start it and try again"
  exit 4
fi
#echo "${DAEMON} PID is" ${PID}

# Find our current blockheight.
OURHIGH=`${CLIENTCMD} getblockcount`
echo "Our latest block is ${OURHIGH}"
OURHASH=`${CLIENTCMD} getblockhash ${OURHIGH}`
#echo "with blockhash ${OURHASH}"
#echo

# Find the current explorer blockheight.
CHAINHIGH=`curl ${EXPLORER}/getblockcount 2>/dev/null`
echo "Latest block at the explorer is ${CHAINHIGH}"
CHAINHASH=`curl ${EXPLORER}/getblockhash?index=${CHAINHIGH} 2>/dev/null`
#echo "with blockhash" ${CHAINHASH}
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
  CHAINHASH=`curl ${EXPLORER}/getblockhash?index=${OURHIGH} 2>/dev/null`
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
#  echo "Low=${LOW} High=${HIGH} Checking ${BLOCK}"
  OURHASH=`${CLIENTCMD} getblockhash ${BLOCK}`
  CHAINHASH=`curl ${EXPLORER}/getblockhash?index=${BLOCK} 2>/dev/null`
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
echo "Forked at ${BLOCK}"
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
  echo "This could leave the chain in an inconsistent state and you might need"
  echo "to start it manually with the -reindex option."
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
