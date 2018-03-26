#!/bin/bash

session=8
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

while [ true ];
do
battle=$((battle+1))
./bash-loop.sh $tf_dir $tf_work $snes9x_dir $smc_dir $rom_name $session $battle;
done

# remove by hand to restart from a specific battle number
echo -e "]" >> $tf_dir/tf_stats_targets.js
echo -e "]" >> $tf_dir/tf_stats_magic.js
echo -e "]" >> $tf_dir/tf_stats_bet.js
