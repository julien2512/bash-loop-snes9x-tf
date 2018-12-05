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
    echo "best_match_zan_minlife=$best_match_zan_minlife" >> ./stats.sh
    echo "time_min=$time_min" >> ./stats.sh
    echo "time_max=$time_max" >> ./stats.sh
    echo "best_match=$best_match" >> ./stats.sh
    echo "win_matchs=\"$win_matchs\"" >> ./stats.sh
    echo "p1_life_loss=$p1_life_loss" >> ./stats.sh
    echo "p2_life_loss=$p2_life_loss" >> ./stats.sh
    echo "time_loss=$time_loss" >> ./stats.sh
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
    echo "var best_match_zan_minlife=$best_match_zan_minlife;" >> ./stats.js
    echo "var time_min=$time_min;" >> ./stats.js
    echo "var time_max=$time_max;" >> ./stats.js
    echo "var best_match=\"$best_match\";" >> ./stats.js
    echo "var win_matchs=\"$win_matchs\";" >> ./stats.js
    echo "var p1_life_loss=$p1_life_loss" >> ./stats.js
    echo "var p2_life_loss=$p2_life_loss" >> ./stats.js
    echo "var time_loss=$time_loss" >> ./stats.js
}
echo_stats() {
echo -e "----------------------------------------------------"
echo -e "Session:$session Battle:$battle"
echo -e "----------------------------------------------------"
echo -e "\tBattles\tRounds\tMax\tMin\tLoose\tMax_t\tMin_t"
echo -e "Ryu\t$ryu_battles\t$ryu_rounds\t$ryu_maxlife\t$ryu_minlife\t$nb_loose1\t$time_max\t$time_min"
echo -e "Zangief\t$zan_battles\t$zan_rounds\t$zan_maxlife\t$zan_minlife\t$nb_loose2"
echo -e "----------------------------------------------------"
echo -e "Best match Zangief life: $best_match_zan_minlife"
echo -e "Best match: $best_match"
echo -e "Win matchs: $win_matchs"
echo -e "loss : p1=$p1_life_loss p2=$p2_life_loss time=$time_loss"
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
  best_match_zan_minlife=176
  best_match=
  win_matchs=
  time_min=147
  time_max=0
  p1_life_loss=0
  p2_life_loss=0
  time_loss=0
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

#echo_stats

# init loop
mkdir -p $tf_dir/$tf_work$i
mkdir -p $tf_dir/"$tf_work"_output$i/images
cp $tf_dir/$tf_work/* $tf_dir/$tf_work$i/

#mkdir -p $tf_dir/$tf_work$((i+1))
#mkdir -p $tf_dir/"$tf_work"_output$((i+1))/images

if [ -d $tf_dir/"$tf_work"_output ];
then
  checkpoint="--checkpoint ""$tf_work""_output"
else
  checkpoint=""
fi

# loop
while [ ! $end -eq 1 ]
do

echo_stats

seed=$[ ( $RANDOM % 1000000 )  + 1 ]

mkdir -p $tf_dir/$tf_work$((i+1))
mkdir -p $tf_dir/"$tf_work"_output$((i+1))/images

# pix2pix.py train i step 1
#   input
#     $tf_work : png + meta + last situation if any
#   output
#     $tf_work : model + outputs + next_commands + situation
cd $tf_dir
python tools/dockrun.py --nogpu True python pix2pix.py --mode train --input_dir $tf_work$i --max_epochs 1 --output_dir "$tf_work"_output$i --display_freq 1 --seed $seed $checkpoint --images 12
# --checkpoint "$tf_work"_output$((i-1) # older release

# bus tf_i => snes9x step 1
cp "$tf_work"_output$i/images/*.next_commands $smc_dir/$rom_name.next_commands

# snes9x-gtk play step 1
#   input
#     $smc_dir : rom_name.smc + rom_name.cht + rom_name.$i
#   output
#     $smc_dir : rom_name.$((i+1)) + rom_name$number.png + rom_name.meta
cd $snes9x_dir/gtk
# number of commands : 12
# snapshot : every 4 frames
# command  : every 4 frames
# sequence size : 48 frames
# number of images : 12 images
xvfb-run -a ./snes9x-gtk -savestateattheendfilename $smc_dir/$rom_name.$((i+1)) -killafterxframes 48 -snapshot $smc_dir/$rom_name.$((i)) -tensorflowcommandsfile1 $smc_dir/$rom_name.next_commands -port1 tensorflow1 -tensorflowrate 4 -autosnapshotrate 4 $smc_dir/$rom_name.smc

# bus snes9x => tf_i step 2
cd $smc_dir
tail -n1 $rom_name.meta > $i.meta_targets.tmp

p1_life=`cat $i.meta_targets.tmp | cut -f1`
p2_life=`cat $i.meta_targets.tmp | cut -f2`
time=`cat $i.meta_targets.tmp | cut -f3`
p1_x1=`cat $i.meta_targets.tmp | cut -f4`
p1_x2=`cat $i.meta_targets.tmp | cut -f5`
p2_x1=`cat $i.meta_targets.tmp | cut -f6`
p2_x2=`cat $i.meta_targets.tmp | cut -f7`

#p2_life correction !
#don't know why
if [ "$p2_life" -eq 255 ];
then
  p2_life=0
fi

echo -e "$p1_life\t$p2_life\t$time\t$p1_x1\t$p1_x2\t$p2_x1\t$p2_x2\t0\t0\t0\t0\t0" > $tf_dir/$tf_work$((i))/$i.meta_targets
rm $i.meta_targets.tmp

# bus snes9x => tf_i+1 step 1
# . meta
# . last 12 images
cd $smc_dir
cp $tf_dir/$tf_work$((i))/$i.meta_targets $tf_dir/$tf_work$((i+1))/$i.meta
if [ $i -eq 0 ];
then
anewer=
else
anewer="-anewer $lastimage"
fi
lastimage=`ls -x1 *.png | tail -n1`
for file in `find *.png $anewer`
do cp $file $tf_dir/$tf_work$((i+1))/${file#Street}
done
#cp `ls -x1 *.png | tail -n12` $tf_dir/$tf_work$((i+1))/

# pix2pix.py train i step 2
#   input
#     $tf_work : png + meta + meta_targets + last situation if any
#   output
#     $tf_work : model + outputs + next_commands + situation
cd $tf_dir
python tools/dockrun.py --nogpu True python pix2pix.py --mode train --input_dir $tf_work$i --max_epochs 1 --output_dir "$tf_work"_output$i --display_freq 1 --seed $seed $checkpoint --images 12 2> tf.out
cat tf.out
targets=`cat tf.out |grep targets|cut -c54- |sed "s/\ /,/g"`
magic=`cat tf.out |grep magic_target|cut -c59- |sed "s/\ /,/g"`
bet=`cat tf.out |grep next_bet|cut -c55- |sed "s/\ /,/g"`
p1_life_loss=`cat tf.out |grep " p1_life_loss"|cut -c59- |sed "s/\ /,/g"`
p2_life_loss=`cat tf.out |grep " p2_life_loss"|cut -c59- |sed "s/\ /,/g"`
time_loss=`cat tf.out |grep " time_loss"|cut -c56- |sed "s/\ /,/g"`
echo -e "//session $session battle $battle step $i" >> tf_stats_targets.js
echo -e "$targets," >> tf_stats_targets.js
echo -e "//session $session battle $battle step $i" >> tf_stats_magic.js
echo -e "$magic," >> tf_stats_magic.js
echo -e "//session $session battle $battle step $i" >> tf_stats_bet.js
echo -e "$bet," >> tf_stats_bet.js
echo -e "//session $session battle $battle step $i" >> tf_stats_loss.js
echo -e "$p1_life_loss\t$p2_life_loss\t$time_loss" >> tf_stats_loss.js
rm tf.out

#render guess values on image
cd $tf_dir/"$tf_work"_output$i/images
guess_p1_life=`cat *.situation | cut -f1`
guess_p2_life=`cat *.situation | cut -f2`
guess_time=`cat *.situation | cut -f3`
cd $smc_dir
for file in `find *.png $anewer`
do convert -pointsize 9 -fill red -draw "text 20,223 \"p1_life=$guess_p1_life p2_life=$guess_p2_life time=$guess_time\" step=$i" $file $file;
done
echo -e "last file : $lastimage"
echo -e "write on it : p1_life=$guess_p1_life p2_life=$guess_p2_life time=$guess_time"

#copy situation to next step
cd $tf_dir/"$tf_work"_output$i/images
cp *.situation $tf_dir/$tf_work$((i+1))

cd $snes9x_dir

# no more time case simulate death
# draw is not taked into account
if [ "$time" -eq 0 ];
then
  if [ "$p1_life" -le "$p2_life" ];
  then
    p1_life=0
  else
    p2_life=0
  fi
fi

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
    time_min="$(min $time_min $time)"
    time_max="$(max $time_max $time)"

    if [ "$p2_life" -lt $best_match_zan_minlife ];
    then
       best_match_zan_minlife=$p2_life
       best_match=$battle
    fi

    write_stats
  fi
else
  if [ "$on_loose1" -eq 1 ];
  then
    on_loose1=0
  fi

  # assume there will not be any draw.
  if [ $p2_life -eq 0 ];
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
      time_min="$(min $time_min $time)"
      time_max="$(max $time_max $time)"
      write_stats
    fi
  else
    if [ "$on_loose2" -eq 1 ];
    then
      on_loose2=0
    fi
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
    if [ "$nb_loose2" -ge 1 ];
    then
      if [ "${#win_matchs}" -eq 0 ];
      then
        win_matchs=$battle
      else
        win_matchs="$win_matchs $battle"
      fi
    fi
    write_stats
fi

checkpoint="--checkpoint ""$tf_work"_output$i

i=$((i+1))

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
cp -R "$tf_work"_output$((i-1))/* "$tf_work"_output

cd $snes9x_dir
write_js_stats

echo "Cleaning"
cd $tf_dir
for j in `seq 0 $i`; do rm -Rf snes9x_inputs$j; done
for j in `seq 0 $i`; do rm -Rf snes9x_inputs_output$j; done

cd $smc_dir
rm *
cp "$smc_dir"_starter/* .
