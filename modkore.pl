BEGIN {
	open "STDERR", "> errors.txt" or die "Could not write to errors.txt: $!\n";
}
use Time::HiRes qw(time usleep);
use IO::Socket;

#mod Start
# init Command Line
	use Win32::Console;
	use Win32::Sound;
	use Digest::MD5 qw(md5);
	use Getopt::Long;
	$def_config = "control";
	$def_table = "tables";
	&GetOptions('config=s',\$def_config,
					   'tables=s',\$def_table,
					   'help',\$help_option
					  );
	if ($help_option) { 
		print "Usage: modKore.exe [options...]\n";
		print "The supported options are:\n";
		print "--help\t\tDisplays this help message.\n";
		print "--config=path\tWhere config folder to use.\n";
		print "--tables=pathe\tWhere tables folder to use.\n";
		exit();
	}
#mod Stop
#cock
srand(time());
