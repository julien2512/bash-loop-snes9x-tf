#!/bin/bash

session=13
battle=0

tf_dir=/data/julien/WORK/pix2pix-tensorflow-snes9x
tf_work=snes9x_inputs
snes9x_dir=/data/julien/WORK/snes9x
smc_dir=/home/julien/.snes9x/rom/SFIIT_tf
rom_name=Street

if [ ! -f "$tf_dir/tf_stats_targets.js" ];
then
  echo -e "[" > $tf_dir/tf_stats_targets.js
fi
if [ ! -f "$tf_dir/tf_stats_magic.js" ];
then
  echo -e "[" > $tf_dir/tf_stats_magic.js
fi
if [ ! -f "$tf_dir/tf_stats_bet.js" ];
then
  echo -e "[" > $tf_dir/tf_stats_bet.js
fi

snapshot=0
if [ -e "$smc_dir"_starter/Street.list ];
then
maxsnapshot=`cat ${smc_dir}_starter/Street.list | wc -l`
echo "$maxsnapshot snapshots loaded"
else
maxsnapshot=0
fi

while [ true ];
do
battle=$((battle+1))

if [ "$maxsnapshot" -gt 0 ];
then
  snapshot=$((snapshot+1))
  if [ "$snapshot" -gt "$maxsnapshot" ];
  then
    snapshot=1
  fi
  snap=`cat ${smc_dir}_starter/Street.list | head -n$snapshot | tail -n1`
  dir=`pwd`
  cd "${smc_dir}_starter"
  cp $snap $smc_dir/Street.0
  cd $dir
fi

./bash-loop.sh $tf_dir $tf_work $snes9x_dir $smc_dir $rom_name $session $battle;
done

# remove by hand to restart from a specific battle number
echo -e "]" >> $tf_dir/tf_stats_targets.js
echo -e "]" >> $tf_dir/tf_stats_magic.js
echo -e "]" >> $tf_dir/tf_stats_bet.js
