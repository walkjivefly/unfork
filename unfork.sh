#!/bin/bash
# unfork.sh
#
# A little script to (attempt) to unfork (get off) a forked blockchain
#
# Method:
# - check if we actually forked, if so:
# - use binary chop to find the fork height
# - invalidateblock the fork point
# - shutdown the daemon
# - remove peers.dat
# - start the daemon
#
# Usage:
#  unfork.sh
# 

# Customise these to suit your environment
COIN="crown"
DATADIR="~/.${COIN}"		# Crown datadir
DAEMON="${COIN}d"		# daemon executable
CLIENT="${COIN}-cli"		# CLI
PREFIX="/usr/local/bin"		# path to Crown executables
EXPLORER="http://92.60.44.199:3001/api"

# Start off by looking for running daemon.
PID=$(pidof ${DAEMON})

# If it's not running we're done.
if [[ $? -eq 1 ]]; then
  echo ${DAEMON} "not running. Please start it and try again"
  exit 4
fi
echo "${DAEMON} PID is" ${PID}

# Find our current blockheight.
OURHIGH=`crown-cli getblockcount`
echo "Our latest block is" ${OURHIGH}
OURHASH=`${CLIENT} getblockhash ${OURHIGH}`
#echo "with blockhash" ${OURHASH}
#echo

# Find the current explorer blockheight.
CHAINHIGH=`curl ${EXPLORER}/getblockcount 2>/dev/null`
echo "Latest block at the explorer is" ${CHAINHIGH}
CHAINHASH=`curl ${EXPLORER}/getblockhash?index=${CHAINHIGH} 2>/dev/null`
#echo "with blockhash" ${CHAINHASH}
echo

# Give the user a sitrep.
if [[ ${OURHIGH} -gt ${CHAINHIGH} ]]; then
  echo "We are ahead of the explorer"
  OURHASH=`${CLIENT} getblockhash ${CHAINHIGH}`
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
LAST=0
LOW=1
while true; do
  BLOCK=$(($(($LOW+$HIGH))/2))
#  echo "Low=${LOW} High=${HIGH} Checking ${BLOCK}"
  OURHASH=`${CLIENT} getblockhash ${BLOCK}`
  CHAINHASH=`curl ${EXPLORER}/getblockhash?index=${BLOCK} 2>/dev/null`
  if [[ ${OURHASH} == ${CHAINHASH} ]]; then
    # go right
    LOW=${BLOCK}
  else
    # go left
    HIGH=${BLOCK}
  fi
  if [[ $LOW == $HIGH ]]; then		# found it
    break
  elif [[ $BLOCK == $LAST ]]; then	# nudge
    LOW=$HIGH
  fi
  LAST=$BLOCK
done
echo "Forked at ${BLOCK}"
echo "Our hash is $OURHASH"
echo "Explorer has $CHAINHASH"

# Invalidate the block.
echo "Invalidating the fork point"
$CLIENT invalidateblock $OURHASH

# Shutdown.
echo "Shutting down the daemon"
$CLIENT stop

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
  rm -f ${DATADIR}/crownd.pid ${DATADIR}/.lock
fi

# Remove peers.dat and restart it. 
# If the installation is "non-standard" you may have to add some more
# parameters to the start command.
rm -f ${DATADIR}/peers.dat
echo "Re-starting the daemon"
${PREFIX}/${DAEMON} -daemon

echo "Use $CLIENT getblockcount to monitor the chain and make sure the daemon"
echo "is resyncing."
