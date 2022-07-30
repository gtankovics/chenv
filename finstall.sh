#!/usr/bin/env fish

set -l userBin ~/bin
set -l execName "fchenv"
set -l execScript $execName".sh"
set -l autocompleteScript $execName".fish"

function checkLink
	if not test -L /usr/local/bin/$execName
		if yesno "Create link in '/usr/local/bin' (sudo required) ?"
			sudo ln -s $userBin/$execName /usr/local/bin/$execName
		else
			echo "Link creation skipped."
		end
	end
end

# copy fchenv
if not test -d $userBin
	mkdir ~/bin
end

if not test -f "$userBin/$execName"
	echo "copy '$execName' to $userBin"
	cp $execScript ~/bin/$execName
	checkLink
else
	if not diff -y -q ./$execScript $userBin/$execName
		if yesno "Show differencies?"
			diff ./$execScript $userBin/$execName
		end
		if yesno "Do you want to create $execName?"
			cp ./$execScript $userBin/$execName
			echo "$execName copied."
			checkLink
		else
			echo "$execName skipped."
		end
	else
		echo "$execName is the latest."
	end
	if not diff -y -q ./completions/$autocompleteScript $__fish_config_dir/completions/$autocompleteScript
		if yesno "Show differenices?"
			diff ./completions/$autocompleteScript ./__fish_config_dir/completions/$autocompleteScript
		end
		if yesno "Do you want to create $autocompleteScript?"
			cp ./completions/$autocompleteScript $__fish_config_dir/completions/$autocompleteScript
			echo "Autocompletie file $autocompleteScript copied."
			checkLink
		else
			echo "Autocompletie file $autocompleteScript skipped."
		end
	else
		echo "Autocompletie file $autocompleteScript is the latest."
	end
end
