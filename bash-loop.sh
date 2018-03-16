#!/bin/bash

if [ -z $1 ] || [ ! -d $1 ];
then usage=true;
echo "Missing 1st parameter";
fi

if [ -z $2 ] || [ ! -d $1/$2 ];
then usage=true;
echo "Missing 2nd parameter";
fi

if [ -z $3 ] || [ ! -d $3 ];
then usage=true;
echo "Missing 3rd parameter";
fi

if [ -z $4 ] || [ ! -d $4 ];
then usage=true;
echo "Missing 4th parameter";
fi

if [ -z $5 ];
then usage=true;
echo "Missing 5th parameter";
fi

if [ -z $6 ];
then usage=true;
echo "Mission 6th parameter";
fi

if [ -z $7 ];
then usage=true;
echo "Mission 7th parameter";
fi

if [ $usage ];
then
echo $0 tf_dir tf_work snes9x_dir smc_dir rom_name session battle
exit
fi

session=$6
battle=$7
tf_dir=$1
tf_work=$2
snes9x_dir=$3
smc_dir=$4
rom_name=$5

min() {
    printf "%s\n" "$@" | sort -g | head -n1
}
max() {
    printf "%s\n" "$@" | sort -g | tail -n1
}
write_stats() {
    echo "#!/bin/bash" > ./stats.sh
    echo "ryu_battles=$ryu_battles" >> ./stats.sh
    echo "ryu_rounds=$ryu_rounds" >> ./stats.sh
    echo "ryu_maxlife=$ryu_maxlife" >> ./stats.sh
    echo "ryu_minlife=$ryu_minlife" >> ./stats.sh
    echo "zan_battles=$zan_battles" >> ./stats.sh
    echo "zan_rounds=$zan_rounds" >> ./stats.sh
    echo "zan_maxlife=$zan_maxlife" >> ./stats.sh
    echo "zan_minlife=$zan_minlife" >> ./stats.sh
}
write_js_stats() {
    echo "var ryu_battles=$ryu_battles;" > ./stats.js
    echo "var ryu_rounds=$ryu_rounds;" >> ./stats.js
    echo "var ryu_maxlife=$ryu_maxlife;" >> ./stats.js
    echo "var ryu_minlife=$ryu_minlife;" >> ./stats.js
    echo "var zan_battles=$zan_battles;" >> ./stats.js
    echo "var zan_rounds=$zan_rounds;" >> ./stats.js
    echo "var zan_maxlife=$zan_maxlife;" >> ./stats.js
    echo "var zan_minlife=$zan_minlife;" >> ./stats.js
}

cd $snes9x_dir
if [ -e "stats.sh" ];
then
  source ./stats.sh
else
  ryu_battles=0
  ryu_rounds=0
  ryu_maxlife=0
  ryu_minlife=176
  zan_battles=0
  zan_rounds=0
  zan_maxlife=0
  zan_minlife=176
fi


echo "bash-loop for tf vs snes9x"
echo "tf_dir : "$tf_dir
echo "tf_work : "$tf_work
echo "snes9x_dir : "$snes9x_dir
echo "smc_dir : "$smc_dir

# assume initial .png and .meta is in $tf_work
# assume initial snapshot 0 is in $smc_dir, $rom_name.smc is in $smc_dir

#one loop
i=0

on_loose1=0
nb_loose1=0
on_loose2=0
nb_loose2=0
end=0

echo -e "-------------------------------------"
echo -e "\tBattles\tRounds\tMax\tMin\tCurrent Loose"
echo -e "Ryu\t$ryu_battles\t$ryu_rounds\t$ryu_maxlife\t$ryu_minlife\t$nb_loose1"
echo -e "Zangief\t$zan_battles\t$zan_rounds\t$zan_maxlife\t$zan_minlife\t$nb_loose2"
echo -e "-------------------------------------"

# init loop
mkdir -p $tf_dir/$tf_work$i
mkdir -p $tf_dir/"$tf_work"_output$i/images
cp $tf_dir/$tf_work/* $tf_dir/$tf_work$i/

mkdir -p $tf_dir/$tf_work$((i+1))
mkdir -p $tf_dir/"$tf_work"_output$((i+1))/images

if [ -d $tf_dir/"$tf_work"_output ];
then
  checkpoint="--checkpoint ""$tf_work""_output"
else
  checkpoint=""
fi

# pix2pix.py train i step 1
#   input
#     $tf_work : png + meta
#   output
#     $tf_work : model + outputs + next_commands
cd $tf_dir
python tools/dockrun.py --nogpu True python pix2pix.py --mode train --input_dir $tf_work$i --max_epochs 1 --output_dir "$tf_work"_output$i --display_freq 1 --seed 12345 $checkpoint

# bus tf_i => snes9x step 1
cp "$tf_work"_output$i/images/*.next_commands $smc_dir/$rom_name.next_commands

# snes9x-gtk play step 1
#   input
#     $smc_dir : rom_name.smc + rom_name.cht + rom_name.$i
#   output
#     $smc_dir : rom_name.$((i+1)) + rom_name$number.png + rom_name.meta
cd $snes9x_dir/gtk
xvfb-run ./snes9x-gtk -savestateattheendfilename $smc_dir/$rom_name.$((i+1)) -killafterxframes 50 -snapshot $smc_dir/$rom_name.$((i)) -tensorflowcommandsfile1 $smc_dir/$rom_name.next_commands -port1 tensorflow1 -tensorflowrate 50 -autosnapshotrate 4 $smc_dir/$rom_name.smc

# bus snes9x => tf_i step 2
cd $smc_dir
tail -n1 $rom_name.meta | sed '/^.*$/ s/$/\t0\t0\t0\t0\t0\t0\t0\t0\t0/' > $tf_dir/$tf_work$((i))/$i.meta_targets

# bus snes9x => tf_i+1 step 1
cd $smc_dir
cp $tf_dir/$tf_work$((i))/$i.meta_targets $tf_dir/$tf_work$((i+1))/$i.meta
cp `ls -x1 *.png | tail -n1` $tf_dir/$tf_work$((i+1))/$i.png

# pix2pix.py train i step 2
#   input
#     $tf_work : png + meta + meta_targets
#   output
#     $tf_work : model + outputs + next_commands
cd $tf_dir
python tools/dockrun.py --nogpu True python pix2pix.py --mode train --input_dir $tf_work$i --max_epochs 1 --output_dir "$tf_work"_output$i --display_freq 1 --seed 12345 $checkpoint

# loop
while [ ! $end -eq 1 ]
do

echo -e "-------------------------------------"
echo -e "\tBattles\tRounds\tMax\tMin\tCurrent Loose"
echo -e "Ryu\t$ryu_battles\t$ryu_rounds\t$ryu_maxlife\t$ryu_minlife\t$nb_loose1"
echo -e "Zangief\t$zan_battles\t$zan_rounds\t$zan_maxlife\t$zan_minlife\t$nb_loose2"
echo -e "-------------------------------------"

i=$((i+1))

mkdir -p $tf_dir/$tf_work$((i+1))
mkdir -p $tf_dir/"$tf_work"_output$((i+1))/images

# pix2pix.py train i step 1
#   input
#     $tf_work : png + meta
#   output
#     $tf_work : model + outputs + next_commands
cd $tf_dir
python tools/dockrun.py --nogpu True python pix2pix.py --mode train --input_dir $tf_work$i --max_epochs 1 --output_dir "$tf_work"_output$i --display_freq 1 --seed 12345 --checkpoint "$tf_work"_output$((i-1))

# bus tf_i => snes9x step 1
cp "$tf_work"_output$i/images/*.next_commands $smc_dir/$rom_name.next_commands

# snes9x-gtk play step 1
#   input
#     $smc_dir : rom_name.smc + rom_name.cht + rom_name.$i
#   output
#     $smc_dir : rom_name.$((i+1)) + rom_name$number.png + rom_name.meta
cd $snes9x_dir/gtk
xvfb-run ./snes9x-gtk -savestateattheendfilename $smc_dir/$rom_name.$((i+1)) -killafterxframes 50 -snapshot $smc_dir/$rom_name.$((i)) -tensorflowcommandsfile1 $smc_dir/$rom_name.next_commands -port1 tensorflow1 -tensorflowrate 50 -autosnapshotrate 4 $smc_dir/$rom_name.smc

# bus snes9x => tf_i step 2
cd $smc_dir
tail -n1 $rom_name.meta | sed '/^.*$/ s/$/\t0\t0\t0\t0\t0\t0\t0\t0\t0/' > $tf_dir/$tf_work$((i))/$i.meta_targets

# bus snes9x => tf_i+1 step 1
cd $smc_dir
cp $tf_dir/$tf_work$((i))/$i.meta_targets $tf_dir/$tf_work$((i+1))/$i.meta
cp `ls -x1 *.png | tail -n1` $tf_dir/$tf_work$((i+1))/$i.png

# pix2pix.py train i step 2
#   input
#     $tf_work : png + meta + meta_targets
#   output
#     $tf_work : model + outputs + next_commands
cd $tf_dir
python tools/dockrun.py --nogpu True python pix2pix.py --mode train --input_dir $tf_work$i --max_epochs 1 --output_dir "$tf_work"_output$i --display_freq 1 --seed 12345 --checkpoint "$tf_work"_output$((i-1))

p1_life=`cat $tf_dir/$tf_work$((i))/$i.meta_targets | cut -f1`
p2_life=`cat $tf_dir/$tf_work$((i))/$i.meta_targets | cut -f2`

cd $snes9x_dir

if [ "$p1_life" -eq 0 ];
then
  if [ "$on_loose1" -eq 0 ];
  then
    on_loose1=1
    echo "########"
    echo "P1 loose"
    echo "########"
    ryu_maxlife="$(max $p1_life $ryu_maxlife)"
    ryu_minlife="$(min $p1_life $ryu_minlife)"
    zan_rounds=$((zan_rounds+1))
    zan_maxlife="$(max $p2_life $zan_maxlife)"
    zan_minlife="$(min $p2_life $zan_minlife)"
    nb_loose1=$((nb_loose1+1))
    write_stats
  fi
else
  if [ "$on_loose1" -eq 1 ];
  then
    on_loose1=0
  fi
fi

if [ "$p2_life" -eq 0 ];
then
  if [ "$on_loose2" -eq 0 ];
  then
    on_loose2=1
    echo "#######"
    echo "P2 loose"
    echo "#######"
    ryu_maxlife="$(max $p1_life $ryu_maxlife)"
    ryu_minlife="$(min $p1_life $ryu_minlife)"
    ryu_rounds=$((ryu_rounds+1))
    zan_maxlife="$(max $p2_life $zan_maxlife)"
    zan_minlife="$(min $p2_life $zan_minlife)"
    nb_loose2=$((nb_loose2+1))
    write_stats
  fi
else
  if [ "$on_loose2" -eq 1 ];
  then
    on_loose2=0
  fi
fi

if [ $nb_loose1 -eq 2 ] || [ $nb_loose2 -eq 2 ];
then
    end=1
    echo "#######"
    echo "END"
    echo "#######"

    if [ "$nb_loose1" -eq 2 ];
    then
      zan_battles=$((zan_battles+1))
    fi
    if [ "$nb_loose2" -eq 2 ];
    then
      ryu_battles=$((ryu_battles+1))
    fi
    write_stats
fi

done

echo "Get gif"
cd $smc_dir
for j in `ls Street*.png`;
do convert -pointsize 20 -fill yellow -draw "text 5,20 \"Session $session Battle $battle\"" $j $j;
done
convert -delay 20 -loop 0 Street*.png $snes9x_dir/street`date +%s`.gif


echo "Saving"
cd $tf_dir
if [ -d "$tf_work"_output/images ];
then
  rm -Rf "$tf_work"_output/*
else
  mkdir -p "$tf_work"_output/images
fi
cp -R "$tf_work"_output$i/* "$tf_work"_output

cd $snes9x_dir
write_js_stats

echo "Cleaning"
cd $tf_dir
for j in `seq 0 $((i+1))`; do rm -Rf snes9x_inputs$j; done
for j in `seq 0 $((i+1))`; do rm -Rf snes9x_inputs_output$j; done

cd $smc_dir
rm *
cp "$smc_dir"_starter/* .