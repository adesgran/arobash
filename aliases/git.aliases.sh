_github ()
{
	if [ -f $1 ] ; then echo "'$1' already exist here";
	else git clone git@github.com:$GIT_USRNAME/$1.git; fi
}

gitall ()
{
	echo Comment for your commit : ;
	read github_commit_msg ;
	git commit -m "$github_commit_msg" ;
	git push origin main ;
}

workspace ()
{
	cd ~/goinfre;
	_github $1;
	cd $1;
}

updatevim ()
{
	workspace vimrc;
	cp .vimrc ~/.vimrc;
	cd ..;
	rm -rf vimrc;
	workspace vim_plugins;
	cp *.vim ~/.vim/plugin;
	cd ..;
	rm -rf vim_plugins;
	cd;
	clear;
}

uploadvim ()
{
	workspace vimrc;
	cp ~/.vimrc .vimrc;
	git add .vimrc;
	git commit -m "Update Vimrc";
	git push origin main;
	cd ..;
	rm -rf vimrc;
	workspace vim_plugins;
	cp ~/.vim/plugin/*.vim .;
	git add *.vim;
	git commit -m "Update Vim Plugins";
	git push origin main;
	cd ..;
	rm -rf vim_plugins;
	cd;
	clear;
}
