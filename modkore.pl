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

#mod Start
# Colored Version , Apply Command Line 
	$CONSOLE = new Win32::Console(STD_OUTPUT_HANDLE) || die "Could not init Console Attribute";
	$CONSOLE->Attr($FG_WHITE|$BG_BLACK);
	$versionText = "***Kore 0.93.17 - Ragnarok Online Bot - http://kore.sourceforge.net***\n";
	$versionText .= "***modKore Lite - http://modkore.sourceforge.net***\n\n";
	print $versionText;
	$CONSOLE->Attr($FG_GRAY);
	addParseFiles("$def_config/config.txt", \%config, \&parseDataFile2);
	addParseFiles("$def_config/items_control.txt", \%items_control, \&parseItemsControl);
	addParseFiles("$def_config/mon_control.txt", \%mon_control, \&parseMonControl);
	addParseFiles("$def_config/ppl_control.txt", \%ppl_control, \&parsePplControl);
	addParseFiles("$def_config/pickupitems.txt", \%itemsPickup, \&parseDataFile_lc);
	addParseFiles("$def_config/timeouts.txt", \%timeout, \&parseTimeouts);
	addParseFiles("$def_config/chatauto.txt", \%qmsg, \&parseChatMsg);
	addParseFiles("$def_config/responses.txt", \%responses, \&parseResponses);
	addParseFiles("$def_config/overallauth.txt", \%overallAuth, \&parseDataFile);
	addParseFiles("$def_config/shop.txt", \%shop, \&parseDataFile2);
	
	addParseFiles("$def_table/cities.txt", \%cities_lut, \&parseROLUT);
	addParseFiles("$def_table/emotions.txt", \%emotions_lut, \&parseDataFile2);
	addParseFiles("$def_table/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2);
	addParseFiles("$def_table/items.txt", \%items_lut, \&parseROLUT);
	addParseFiles("$def_table/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2);
	addParseFiles("$def_table/jobs.txt", \%jobs_lut, \&parseDataFile2);
	addParseFiles("$def_table/maps.txt", \%maps_lut, \&parseROLUT);
	addParseFiles("$def_table/monsters.txt", \%monsters_lut, \&parseDataFile2);
	addParseFiles("$def_table/npcs.txt", \%npcs_lut, \&parseNPCs);
	addParseFiles("$def_table/portals.txt", \%portals_lut, \&parsePortals);
	addParseFiles("$def_table/portalsLOS.txt", \%portals_los, \&parsePortalsLOS);
	addParseFiles("$def_table/sex.txt", \%sex_lut, \&parseDataFile2);
	addParseFiles("$def_table/skills.txt", \%skills_lut, \&parseSkillsLUT);
	addParseFiles("$def_table/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
	addParseFiles("$def_table/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
	addParseFiles("$def_table/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);

	addParseFiles("$def_table/recvpackets.txt", \%rpackets, \&parseDataFile2);
	addParseFiles("$def_table/skillsst.txt", \%skillsST_lut, \&parseDataFile2);
	addParseFiles("$def_table/cards.txt", \%cards_lut, \&parseROLUT);
	addParseFiles("$def_table/elements.txt", \%elements_lut, \&parseROLUT);
	addParseFiles("$def_table/aids.txt", \%GameMasters, \&parseDataFile3);
	addParseFiles("$def_table/modifiedWalk.txt", \%modifiedWalk, \&parseDataFile2);
load(\@parseFiles);
#mod Stop

if ($^O eq 'MSWin32') {
	eval "use Win32::API;";
	die if ($@);
	$CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPNNPPN", "N") || die "Could not locate Tools.dll";

	$CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N") || die "Could not locate Tools.dll";

	$CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V") || die "Could not locate Tools.dll";

} else{
	eval "use C::DynaLib;";
	eval "use POSIX \":sys_wait_h\";";
	die if ($@);
	$ToolsLib = new C::DynaLib("./Tools.so");

	$CalcPath_init = $ToolsLib->DeclareSub("CalcPath_init", "L", "p","p","L","L","p","p","L") || die "Could not locate Tools.so";

	$CalcPath_pathStep = $ToolsLib->DeclareSub("CalcPath_pathStep", "L", "L") || die "Could not locate Tools.so";

	$CalcPath_destroy = $ToolsLib->DeclareSub("CalcPath_destroy", "", "L") || die "Could not locate Tools.so";
}

if ($config{'adminPassword'} eq 'x' x 10) {
	print "\nAuto-generating Admin Password\n";
	configModify("adminPassword", vocalString(8));
}

print "\n";

$proto = getprotobyname('tcp');
our $MAX_READ = 30000;

our $remote_socket = IO::Socket::INET->new();
our $server_socket = IO::Socket::INET->new(
			Listen		=> 5,
			LocalAddr	=> $config{'local_host'},
			LocalPort	=> $config{'local_port'},
			Proto		=> 'tcp',
			Timeout		=> 2,
			Reuse		=> 1) || die "Error creating local input server: $!";

print "Local server started ($config{'local_host'}:$config{'local_port'})\n";

our $input_pid = input_client();
$conState = 1;


###COMPILE PORTALS###

print "\nChecking for new portals...";
compilePortals_check(\$found);

if ($found) {
	print "found new portals!\n";
	print "Compile portals now? (y/n)\n";
	print "Auto-compile in $timeout{'compilePortals_auto'}{'timeout'} seconds...";
	$timeout{'compilePortals_auto'}{'time'} = time;
	undef $msg;
	while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
		if (dataWaiting(\$input_socket)) {
			$input_socket->recv($msg, $MAX_READ);
		}
		last if $msg;
	}
	if ($msg =~ /y/ || $msg eq "") {
		print "compiling portals\n\n";
		compilePortals();
	} else {
		print "skipping compile\n\n";
	}
} else {
	print "none found\n";
}


if (!$config{'username'}) {
	print "Enter Username:\n";
	$input_socket->recv($msg, $MAX_READ);
	$config{'username'} = $msg;
	writeDataFileIntact("$def_config/config.txt", \%config);
	
}
if (!$config{'password'}) {
	print "Enter Password:\n";
	$input_socket->recv($msg, $MAX_READ);
	$config{'password'} = $msg;
	writeDataFileIntact("$def_config/config.txt", \%config);
}
if ($config{'master'} eq "") {
	$i = 0;
	$~ = "MASTERS";
	print "--------- Master Servers ----------\n";
	print "#         Name\n";
	while ($config{"master_name_$i"} ne "") {
		format MASTERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i  $config{"master_name_$i"}
.
		write;
		$i++;
	}
	print "-------------------------------\n";
	print "Choose your master server:\n";
	$input_socket->recv($msg, $MAX_READ);
	$config{'master'} = $msg;
	writeDataFileIntact("$def_config/config.txt", \%config);
}
undef $msg;
$KoreStartTime = time;
#mod Start
# Display username in Title Bar
	$CONSOLE->Title("Kore : $config{'username'}");
#mod Stop
while ($quit != 1) {
	usleep($config{'sleepTime'});
	if (dataWaiting(\$input_socket)) {
		$input_socket->recv($input, $MAX_READ);
		parseInput($input);
	} elsif (dataWaiting(\$remote_socket)) {
		$remote_socket->recv($new, $MAX_READ);
		$msg .= $new;
		$msg_length = length($msg);
		while ($msg ne "") {
			$msg = parseMsg($msg);
			last if ($msg_length == length($msg));
			$msg_length = length($msg);
		}
	}
	$ai_cmdQue_shift = 0;
	do {
		AI(\%{$ai_cmdQue[$ai_cmdQue_shift]}) if ($conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());
		undef %{$ai_cmdQue[$ai_cmdQue_shift++]};
		$ai_cmdQue-- if ($ai_cmdQue > 0);
	} while ($ai_cmdQue > 0);
	checkConnection();
}
close($server_socket);
close($input_socket);
close($remote_socket);
kill 9, $input_pid;
killConnection(\$remote_socket);
$CONSOLE->Attr($FG_WHITE|$BG_BLACK);
print "Bye!\n";
print $versionText;
$CONSOLE->Attr($FG_GRAY);
exit;

#######################################
#INITIALIZE VARIABLES
#######################################

sub initConnectVars {
	initMapChangeVars();
	undef @{$chars[$config{'char'}]{'inventory'}};
	undef %{$chars[$config{'char'}]{'skills'}};
	undef @skillsID;
}

sub initMapChangeVars {
	@portalsID_old = @portalsID;
	%portals_old = %portals;
	%{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
	undef $chars[$config{'char'}]{'sitting'};
	undef $chars[$config{'char'}]{'dead'};
	$timeout{'play'}{'time'} = time;
	$timeout{'ai_sync'}{'time'} = time;
	$timeout{'ai_sit_idle'}{'time'} = time;
	$timeout{'ai_teleport_idle'}{'time'} = time;
	$timeout{'ai_teleport_search'}{'time'} = time;
	$timeout{'ai_teleport_safe_force'}{'time'} = time;
	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	undef $currentChatRoom;
	undef @currentChatRoomUsers;
	undef @playersID;
	undef @monstersID;
	undef @portalsID;
	undef @itemsID;
	undef @npcsID;
	undef @identifyID;
	undef @spellsID;
	undef @petsID;
	undef %players;
	undef %monsters;
	undef %portals;
	undef %items;
	undef %npcs;
	undef %spells;
	undef %incomingParty;
	undef $msg;
	undef %talk;
	undef %{$ai_v{'temp'}};
#Cart List bugfix - chobit aska 20030128
	undef @cartID;
	undef %{$cart{'inventory'}};
#mod Start
# undef for ChatAuto , Q'pet , Vender
	undef %ppllog;
	undef @venderItemList; 
	undef $venderID; 
	undef @venderListsID; 
	undef $venderLists; 
# Stuck Killer
	undef $old_x;
	undef $old_y;
	undef $old_pos_x;
	undef $old_pos_y;
	undef $move_x;
	undef $move_y;
	undef $move_pos_x;
	undef $move_pos_y;
	$calcFrom_SameSpot = 0;
	$calcTo_SameSpot = 0;
	$moveFrom_SameSpot = 0;
	$moveTo_SameSpot = 0;
	$route_stuck = 0;
	$totalStuckCount = 0 if ($totalStuckCount > 10 || $totalStuckCount < 0);
#guild
	undef %guild;
	undef %incomingGuild;
#mod Stop
}



#######################################
#######################################
#Check Connection
#######################################
#######################################



sub checkConnection {
	
	if ($conState == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$conState_tries) {
		print "Connecting to Master Server...\n";
		$conState_tries++;
		undef $msg;
		connection(\$remote_socket, $config{"master_host_$config{'master'}"},$config{"master_port_$config{'master'}"});
#mod Start
# Secure Login
		if ($remote_socket && $remote_socket->connected()){
			if ($config{'SecureLogin'}) {
				undef $encrypt_key;
				print "Secure Login : Sending Request Key \n";
				sendMasterEncryptKeyRequest(\$remote_socket);
			}else{
				sendMasterLogin(\$remote_socket, $config{'username'}, $config{'password'});
			}
		}
		$timeout{'master'}{'time'} = time;
	} elsif ($conState == 1 && $config{'SecureLogin'} == 1 && $encrypt_key ne "" && !timeOut(\%{$timeout{'master'}}) && $conState_tries) {
		print "Secure Login : Encrypt password\n";
		sendMasterSecureLogin(\$remote_socket, $config{'username'}, $config{'password'}, $encrypt_key);
		undef $encrypt_key;
#mod Stop
	} elsif ($conState == 1 && timeOut(\%{$timeout{'master'}}) && timeOut(\%{$timeout_ex{'master'}})) {
		print "Timeout on Master Server, reconnecting...\n";
		killConnection(\$remote_socket);
		undef $conState_tries;

	} elsif ($conState == 2 && !($remote_socket && $remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$conState_tries) {
		print "Connecting to Game Login Server...\n";
		$conState_tries++;
		if ($config{'charServer_host'}) {
			connection(\$remote_socket, $config{'charServer_host'},$config{'charServer_port'});
		} else {
			connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
		}
		sendGameLogin(\$remote_socket, $accountID, $sessionID, $sessionID2 ,$accountSex);
		$timeout{'gamelogin'}{'time'} = time;

	} elsif ($conState == 2 && timeOut(\%{$timeout{'gamelogin'}}) && ($config{'server'} ne "" || $config{'charServer_host'})) {
		print "Timeout on Game Login Server, reconnecting...\n";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$remote_socket);
		undef $conState_tries;
		$conState = 1;

	} elsif ($conState == 3 && !($remote_socket && $remote_socket->connected()) && $config{'char'} ne "" && !$conState_tries) {
		print "Connecting to Game Login Server...\n";
		$conState_tries++;
		connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
		sendCharLogin(\$remote_socket, $config{'char'});
		$timeout{'charlogin'}{'time'} = time;

	} elsif ($conState == 3 && timeOut(\%{$timeout{'gamelogin'}}) && $config{'char'} ne "") {
		print "Timeout on Char Login Server, reconnecting...\n";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 4 && !($remote_socket && $remote_socket->connected()) && !$conState_tries) {
		print "Connecting to Map Server...\n";
		$conState_tries++;
		initConnectVars();
		connection(\$remote_socket, $map_ip, $map_port);
		sendMapLogin(\$remote_socket, $accountID, $charID, $sessionID, $accountSex2);
		$timeout{'maplogin'}{'time'} = time;

	} elsif ($conState == 4 && timeOut(\%{$timeout{'maplogin'}})) {
		print "Timeout on Map Server, connecting to Master Server...\n";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 5 && !($remote_socket && $remote_socket->connected())) {
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 5 && timeOut(\%{$timeout{'play'}})) {
		print "Timeout on Map Server, connecting to Master Server...\n";
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;
	}
	if ($config{'autoRestart'} && time - $KoreStartTime > $config{'autoRestart'}) {
		$conState = 1;
		undef $conState_tries;
		undef %ai_v;
		undef @ai_seq;
		undef @ai_seq_args;
		$KoreStartTime = time;
		print "\nAuto-restarting!!\n\n";
		killConnection(\$remote_socket);
	}
}


#######################################
#PARSE INPUT
#######################################


sub parseInput {
	my $input = shift;
	my ($arg1, $arg2, $switch);
	print "Echo: $input\n" if ($config{'debug'} >= 2);
	($switch) = $input =~ /^(\w*)/;

#Check if in special state

	if ($conState == 2 && $waitingForInput) {
		$config{'server'} = $input;
		$waitingForInput = 0;
		writeDataFileIntact("$def_config/config.txt", \%config);
	} elsif ($conState == 3 && $waitingForInput) {
		$config{'char'} = $input;
		$waitingForInput = 0;
		writeDataFileIntact("$def_config/config.txt", \%config);
		sendCharLogin(\$remote_socket, $config{'char'});
		$timeout{'gamelogin'}{'time'} = time;


#Parse command...ugh

	} elsif ($switch eq "a") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;
		if ($arg1 =~ /^\d+$/ && $monstersID[$arg1] eq "") {
			print	"Error in function 'a' (Attack Monster)\n"
				,"Monster $arg1 does not exist.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			attack($monstersID[$arg1]);

		} elsif ($arg1 eq "no") {
			configModify("attackAuto", 1);
		
		} elsif ($arg1 eq "yes") {
			configModify("attackAuto", 2);

		} else {
			print	"Syntax Error in function 'a' (Attack Monster)\n"
				,"Usage: attack <monster # | no | yes >\n";
		}
#mod Start
# ai Status
	}elsif ($switch eq "as" ){
		$stuff = @ai_seq_args;
		print "AI: @ai_seq | $stuff\n";
#mod Stop
	} elsif ($switch eq "auth") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
		if ($arg1 eq "" || ($arg2 ne "1" && $arg2 ne "0")) {
			print	"Syntax Error in function 'auth' (Overall Authorize)\n"
				,"Usage: auth <username> <flag>\n";
		} else {
			auth($arg1, $arg2);
		}
#mod Start
#force command
	} elsif ($switch eq "autostorage") {
		unshift @ai_seq, "storageAuto";
		unshift @ai_seq_args, {};

	} elsif ($switch eq "autobuy") {
		unshift @ai_seq, "buyAuto";
		unshift @ai_seq_args, {};

	} elsif ($switch eq "autosell") {
		unshift @ai_seq, "sellAuto";
		unshift @ai_seq_args, {};
#mod Stop
	} elsif ($switch eq "bestow") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			print	"Error in function 'bestow' (Bestow Admin in Chat)\n"
				,"You are not in a Chat Room.\n";
		} elsif ($arg1 eq "") {
			print	"Syntax Error in function 'bestow' (Bestow Admin in Chat)\n"
				,"Usage: bestow <user #>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			print	"Error in function 'bestow' (Bestow Admin in Chat)\n"
				,"Chat Room User $arg1 doesn't exist\n";
		} else {
			sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "buy") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'buy' (Buy Store Item)\n"
				,"Usage: buy <item #> [<amount>]\n";
		} elsif ($storeList[$arg1] eq "") {
			print	"Error in function 'buy' (Buy Store Item)\n"
				,"Store Item $arg1 does not exist.\n";
		} else {
			if ($arg2 <= 0) {
				$arg2 = 1;
			}
			sendBuy(\$remote_socket, $storeList[$arg1]{'nameID'}, $arg2);
		}

	} elsif ($switch eq "c") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'c' (Chat)\n"
				,"Usage: c <message>\n";
		} else {
			sendMessage(\$remote_socket, "c", $arg1);
		}

	#Cart command - chobit andy 20030101
	} elsif ($switch eq "cart") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "CARTLIST";
			print "-------------Cart--------------\n";
			print "#  Name\n";
			
			for ($i=0; $i < @cartID; $i++) {
				next if ($cartID[$i] eq "");
				$display = "$cart{'inventory'}{$cartID[$i]}{'name'} x $cart{'inventory'}{$cartID[$i]}{'amount'}";
				format CARTLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i $display
.
				write;
			}
			print "\nCapacity: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  Weight: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . "\n";
			print "-------------------------------\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			print	"Error in function 'cart add' (Add Item to Cart)\n"
				,"Inventory Item $arg2 does not exist.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
		} elsif ($arg1 eq "add" && $arg2 eq "") {
			print	"Syntax Error in function 'cart add' (Add Item to Cart)\n"
				,"Usage: cart add <item #>\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}{$cartID[$arg2]}}) {
			print	"Error in function 'cart get' (Get Item from Cart)\n"
				,"Cart Item $arg2 does not exist.\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $cart{'inventory'}{$cartID[$arg2]}{'amount'}) {
				$arg3 = $cart{'inventory'}{$cartID[$arg2]}{'amount'};
			}
			sendCartGet(\$remote_socket, $cart{'inventory'}{$cartID[$arg2]}{'index'}, $arg3);
		} elsif ($arg1 eq "get" && $arg2 eq "") {
			print	"Syntax Error in function 'cart get' (Get Item from Cart)\n"
				,"Usage: cart get <cart item #>\n";
		}


	} elsif ($switch eq "chat") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"Syntax Error in function 'chat' (Create Chat Room)\n"
				,qq~Usage: chat "<title>" [<limit #> <public flag> <password>]\n~;
		} elsif ($currentChatRoom ne "") {
			print	"Error in function 'chat' (Create Chat Room)\n"
				,"You are already in a chat room.\n";
		} else {
			if ($arg[0] eq "") {
				$arg[0] = 20;
			}
			if ($arg[1] eq "") {
				$arg[1] = 1;
			}
			sendChatRoomCreate(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
			$createdChatRoom{'title'} = $title;
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = $arg[0];
			$createdChatRoom{'public'} = $arg[1];
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
		}


	} elsif ($switch eq "chatmod") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"Syntax Error in function 'chatmod' (Modify Chat Room)\n"
				,qq~Usage: chatmod "<title>" [<limit #> <public flag> <password>]\n~;
		} else {
			if ($arg[0] eq "") {
				$arg[0] = 20;
			}
			if ($arg[1] eq "") {
				$arg[1] = 1;
			}
			sendChatRoomChange(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
		}
#Mod Start
#Sraet Chat Viewer
	} elsif ($switch eq "chist") {
		my (@chat);
		open(CHAT, "logs\/$config{'username'}_Chat.txt") or print("Unable to open Chat file. \n"); 
		@chat = <CHAT>; 
		close(CHAT); 
		print "------ Chat History --------------------\n"; 
		for ($i = @chat - 5; $i < @chat;$i++) { 
			print $chat[$i]; 
		} 
		print "----------------------------------------\n"; 
#Mod Stop
	} elsif ($switch eq "cl") { 
		chatLog_clear();
		print qq~Chat log cleared.\n~; 

	} elsif ($switch eq "conf") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
		@{$ai_v{'temp'}{'conf'}} = keys %config;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'conf' (Config Modify)\n"
				,"Usage: conf <variable> [<value>]\n";
		} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
			print "Config variable $arg1 doesn't exist\n";
		} elsif ($arg2 eq "value") {
			print "Config '$arg1' is $config{$arg1}\n";
		} else {
			configModify($arg1, $arg2);
		}

	} elsif ($switch eq "cri") {
		if ($currentChatRoom eq "") {
			print "There is no chat room info - you are not in a chat room\n";
		} else {
			$~ = "CRI";
			print	"-----------Chat Room Info-----------\n"
				,"Title                     Users   Public/Private\n";
			$public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
			$limit_string = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};
			format CRI =
@<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<< @<<<<<<<<<
$chatRooms{$currentChatRoom}{'title'} $limit_string $public_string
.
			write;
			$~ = "CRIUSERS";
			print	"-- Users --\n";
			for ($i = 0; $i < @currentChatRoomUsers; $i++) {
				next if ($currentChatRoomUsers[$i] eq "");
				$user_string = $currentChatRoomUsers[$i];
				$admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(Admin)" : "";
				format CRIUSERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
$i  $user_string               $admin_string
.
				write;
			}
			print "------------------------------------\n";
		}

	} elsif ($switch eq "crl") {
		$~ = "CRLIST";
		print	"-----------Chat Room List-----------\n"
			,"#   Title                     Owner                Users   Public/Private\n";
		for ($i = 0; $i < @chatRoomsID; $i++) {
			next if ($chatRoomsID[$i] eq "");
			$owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
			$public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Public" : "Private";
			$limit_string = $chatRooms{$chatRoomsID[$i]}{'num_users'}."/".$chatRooms{$chatRoomsID[$i]}{'limit'};
			format CRLIST = 
@<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<          @<<<<<< @<<<<<<<<<
$i  $chatRooms{$chatRoomsID[$i]}{'title'}          $owner_string $limit_string $public_string
.
			write;
		}
		print "------------------------------------\n";

	} elsif ($switch eq "deal") {
		@arg = split / /, $input;
		shift @arg;
		if (%currentDeal && $arg[0] =~ /\d+/) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"You are already in a deal\n";
		} elsif (%incomingDeal && $arg[0] =~ /\d+/) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"You must first cancel the incoming deal\n";
		} elsif ($arg[0] =~ /\d+/ && !$playersID[$arg[0]]) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"Player $arg[0] does not exist\n";
		} elsif ($arg[0] =~ /\d+/) {
			$outgoingDeal{'ID'} = $playersID[$arg[0]];
			sendDeal(\$remote_socket, $playersID[$arg[0]]);


		} elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"There is no incoming/current deal to cancel\n";
		} elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
			sendDealCancel(\$remote_socket);
		} elsif ($arg[0] eq "no" && %currentDeal) {
			sendCurrentDealCancel(\$remote_socket);


		} elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"There is no deal to accept\n";
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"Cannot make the trade - $currentDeal{'name'} has not finalized\n";
		} elsif ($arg[0] eq "" && $currentDeal{'final'}) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"You already accepted the final deal\n";
		} elsif ($arg[0] eq "" && %incomingDeal) {
			sendDealAccept(\$remote_socket);
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
			sendDealTrade(\$remote_socket);
			$currentDeal{'final'} = 1;
			print "You accepted the final Deal\n";
		} elsif ($arg[0] eq "" && %currentDeal) {
			sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
			sendDealFinalize(\$remote_socket);
			

		} elsif ($arg[0] eq "add" && !%currentDeal) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"No deal in progress\n";
		} elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"Can't add any Items - You already finalized the deal\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"Inventory Item $arg[1] does not exist.\n";
		} elsif ($arg[0] eq "add" && $arg[2] && $arg[2] !~ /\d+/) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"Amount must either be a number, or not specified.\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/) {
			if (scalar(keys %{$currentDeal{'you'}}) < 10) {
				if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
					$arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
				}
				$currentDeal{'lastItemAmount'} = $arg[2];
				sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
			} else {
				print "You can't add any more items to the deal\n";
			}
		} elsif ($arg[0] eq "add" && $arg[1] eq "z") {
			if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
				$arg[2] = $chars[$config{'char'}]{'zenny'};
			}
			$currentDeal{'you_zenny'} = $arg[2];
			print "You put forward $arg[2] z to Deal\n";

		} else {
			print	"Syntax Error in function 'deal' (Deal a player)\n"
				,"Usage: deal [<Player # | no | add>] [<item #>] [<amount>]\n";
		}

	} elsif ($switch eq "dl") {
		if (!%currentDeal) {
			print "There is no deal list - You are not in a deal\n";

		} else {
			print	"-----------Current Deal-----------\n";
			$other_string = $currentDeal{'name'};
			$you_string = "You";
			if ($currentDeal{'other_finalize'}) {
				$other_string .= " - Finalized";
			}
			if ($currentDeal{'you_finalize'}) {
				$you_string .= " - Finalized";
			}
		
			$~ = "PREDLIST";
			format PREDLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$you_string                      $other_string
.
			write;
			$~ = "DLIST";
			undef @currentDealYou;
			undef @currentDealOther;
			foreach (keys %{$currentDeal{'you'}}) {
				push @currentDealYou, $_;
			}
			foreach (keys %{$currentDeal{'other'}}) {
				push @currentDealOther, $_;
			}
			$lastindex = @currentDealOther;
			$lastindex = @currentDealYou if (@currentDealYou > $lastindex);
			for ($i = 0; $i < $lastindex; $i++) {
				if ($i < @currentDealYou) {
					$display = ($items_lut{$currentDealYou[$i]} ne "") 
						? $items_lut{$currentDealYou[$i]}
						: "Unknown ".$currentDealYou[$i];
					$display .= " x $currentDeal{'you'}{$currentDealYou[$i]}{'amount'}";
				} else {
					$display = "";
				}
				if ($i < @currentDealOther) {
					$display2 = ($items_lut{$currentDealOther[$i]} ne "") 
						? $items_lut{$currentDealOther[$i]}
						: "Unknown ".$currentDealOther[$i];
					$display2 .= " x $currentDeal{'other'}{$currentDealOther[$i]}{'amount'}";
				} else {
					$display2 = "";
				}
				format DLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$display                         $display2
.
				write;
			}
			$you_string = ($currentDeal{'you_zenny'} ne "") ? $currentDeal{'you_zenny'} : 0;
			$other_string = ($currentDeal{'other_zenny'} ne "") ? $currentDeal{'other_zenny'} : 0;
			$~ = "DLISTSUF";
			format DLISTSUF =
Zenny: @<<<<<<<<<<<<<            Zenny: @<<<<<<<<<<<<<
$you_string                      $other_string
.
			write;
			print "----------------------------------\n";
		}


	} elsif ($switch eq "drop") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'drop' (Drop Inventory Item)\n"
				,"Usage: drop <item #> [<amount>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'drop' (Drop Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "dump") {
		dumpData($msg);

	} elsif ($switch eq "e") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "" || $arg1 > 33 || $arg1 < 0) {
			print	"Syntax Error in function 'e' (Emotion)\n"
				,"Usage: e <emotion # (0-33)>\n";
		} else {
			sendEmotion(\$remote_socket, $arg1);
		}

	} elsif ($switch eq "eq") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\w+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'equip' (Equip Inventory Item)\n"
				,"Usage: equip <item #> [r]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'equip' (Equip Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 0 && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
			print	"Error in function 'equip' (Equip Inventory Item)\n"
				,"Inventory Item $arg1 can't be equipped.\n";
		} else {
			sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'});
		}

	} elsif ($switch eq "follow") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'follow' (Follow Player)\n"
				,"Usage: follow <player #>\n";
		} elsif ($arg1 eq "stop") {
			aiRemove("follow");
			configModify("follow", 0);
		} elsif ($playersID[$arg1] eq "") {
			print	"Error in function 'follow' (Follow Player)\n"
				,"Player $arg1 does not exist.\n";
		} else {
			ai_follow($players{$playersID[$arg1]}{'name'});
			configModify("follow", 1);
			configModify("followTarget", $players{$playersID[$arg1]}{'name'});
		}

	#Guild Chat - chobit andy 20030101
	} elsif ($switch eq "g") { 
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/; 
		if ($arg1 eq "") { 
			print "Syntax Error in function 'g' (Guild Chat)\n" 
				,"Usage: g <message>\n"; 
		} else { 
			sendMessage(\$remote_socket, "g", $arg1); 
		}

	} elsif ($switch eq "guild") {
		($arg1) = $input =~ /^.*? (\w+)/;
		if ($arg1 eq "info") {
			print "---------- Guild Information ----------\n";
			$~ = "GUILD";
			format GUILD =
Name    : @<<<<<<<<<<<<<<<<<<<<<<<<
$guild{'name'}
Lv      : @<<
$guild{'lvl'}
Exp     : @>>>>>>>>>/@<<<<<<<<<<
$guild{'exp'} $guild{'next_exp'}
Master  : @<<<<<<<<<<<<<<<<<<<<<<<<
$guild{'master'}
Connect : @>>/@<<
$guild{'conMember'} $guild{'maxMember'}
.
			write;
			print "---------------------------------------\n";
		} elsif ($arg1 eq "member") {
			print "------------ Guild  Member ------------\n";
			print "Name              Job        Lv Title            Online\n";
			$~ = "GM";
			format GM = 
@<<<<<<<<<<<<<<<< @<<<<<<<<< @> @<<<<<<<<<<<<<<<<<< @>>
$name                    $job       $lvl $title                   $online
.
			for ($i = 0; $i < $guild{'members'}; $i++) {
				next if ($name eq "");
				$name  = $guild{'member'}[$i]{'name'};
				$job   = $jobs_lut{$guild{'member'}[$i]{'jobID'}};
				$lvl   = $guild{'member'}[$i]{'lvl'};
				$title = $guild{'member'}[$i]{'title'};
				$online = $guild{'member'}[$i]{'online'} ? "Yes" : "No";
				write;
			}
			print "---------------------------------------\n";
		} elsif ($arg1 eq "") {
			print "Requesting : guild information\n",
				    "Usage: guild < info | member >\n";
			sendGuildInfoRequest(\$remote_socket);
			sendGuildRequest(\$remote_socket, 0);
			sendGuildRequest(\$remote_socket, 1);
		}

	} elsif ($switch eq "i") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
			undef @useable;
			undef @equipment;
			undef @non_useable;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
#mod Start
# Fix Show items
				if ($chars[$config{'char'}]{'inventory'}[$i]{'type'} == 3 
					||$chars[$config{'char'}]{'inventory'}[$i]{'type'} == 6
					||$chars[$config{'char'}]{'inventory'}[$i]{'type'} == 10) {
					push @non_useable, $i;
				} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
					push @useable, $i;
				} else {
					push @equipment, $i;
				}
#mod Stop
			}
			$~ = "INVENTORY";
			format INVENTORY =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$index   $display
.
			print	"-----------Inventory-----------\n";
			if ($arg1 eq "" || $arg1 eq "eq") {
				print	"-- Equipment --\n";
				for ($i = 0; $i < @equipment; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'amount'}";
					if ($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'}) {
						$display .= " -- Eqp: $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'}}";
					}
					if (!$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'identified'}) {
						$display .= " -- Not Identified";
					}
					$index = $equipment[$i];
					write;
				}
			}
			if ($arg1 eq "" || $arg1 eq "nu") {
				print	"-- Non-Useable --\n";
				for ($i = 0; $i < @non_useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'amount'}";
					$index = $non_useable[$i];
					write;
				}
			}
			if ($arg1 eq "" || $arg1 eq "u") {
				print	"-- Useable --\n";
				for ($i = 0; $i < @useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'amount'}";
					$index = $useable[$i];
					write;
				}
			}
			print "-------------------------------\n";

		} else {
			print	"Syntax Error in function 'i' (Iventory List)\n"
				,"Usage: i [<u|eq|nu>]\n";
		}

	} elsif ($switch eq "identify") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			$~ = "IDENTIFY";
			print	"---------Identify List--------\n";
			for ($i = 0; $i < @identifyID; $i++) {
				next if ($identifyID[$i] eq "");
				format IDENTIFY =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i   $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'}
.
				write;
			}
			print	"------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $identifyID[$arg1] eq "") {
			print	"Error in function 'identify' (Identify Item)\n"
				,"Identify Item $arg1 does not exist\n";

		} elsif ($arg1 =~ /\d+/) {
			sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
		} else {
			print	"Syntax Error in function 'identify' (Identify Item)\n"
				,"Usage: identify [<identify #>]\n";
		}


	} elsif ($switch eq "ignore") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
		if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
			print	"Syntax Error in function 'ignore' (Ignore Player/Everyone)\n"
				,"Usage: ignore <flag> <name | all>\n";
		} else {
			if ($arg2 eq "all") {
				sendIgnoreAll(\$remote_socket, !$arg1);
			} else {
				sendIgnore(\$remote_socket, $arg2, !$arg1);
			}
		}

	} elsif ($switch eq "il") {
		$~ = "ILIST";
		print	"-----------Item List-----------\n"
			,"#    Name                      \n";
		for ($i = 0; $i < @itemsID; $i++) {
			next if ($itemsID[$i] eq "");
			$display = $items{$itemsID[$i]}{'name'};
			$display .= " x $items{$itemsID[$i]}{'amount'}";
			format ILIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i   $display
.
			write;
		}
		print "-------------------------------\n";

	} elsif ($switch eq "im") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'im' (Use Item on Monster)\n"
				,"Usage: im <item #> <monster #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'im' (Use Item on Monster)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			print	"Error in function 'im' (Use Item on Monster)\n"
				,"Inventory Item $arg1 is not of type Usable.\n";
		} elsif ($monstersID[$arg2] eq "") {
			print	"Error in function 'im' (Use Item on Monster)\n"
				,"Monster $arg2 does not exist.\n";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
		}

	} elsif ($switch eq "ip") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'ip' (Use Item on Player)\n"
				,"Usage: ip <item #> <player #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'ip' (Use Item on Player)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			print	"Error in function 'ip' (Use Item on Player)\n"
				,"Inventory Item $arg1 is not of type Usable.\n";
		} elsif ($playersID[$arg2] eq "") {
			print	"Error in function 'ip' (Use Item on Player)\n"
				,"Player $arg2 does not exist.\n";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
		}

	} elsif ($switch eq "is") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'is' (Use Item on Self)\n"
				,"Usage: is <item #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'is' (Use Item on Self)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			print	"Error in function 'is' (Use Item on Self)\n"
				,"Inventory Item $arg1 is not of type Usable.\n";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
		}

	} elsif ($switch eq "join") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'join' (Join Chat Room)\n"
				,"Usage: join <chat room #> [<password>]\n";
		} elsif ($currentChatRoom ne "") {
			print	"Error in function 'join' (Join Chat Room)\n"
				,"You are already in a chat room.\n";
		} elsif ($chatRoomsID[$arg1] eq "") {
			print	"Error in function 'join' (Join Chat Room)\n"
				,"Chat Room $arg1 does not exist.\n";
		} else {
			sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
		}

	} elsif ($switch eq "judge") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'judge' (Give an alignment point to Player)\n"
				,"Usage: judge <player #> <0 (good) | 1 (bad)>\n";
		} elsif ($playersID[$arg1] eq "") {
			print	"Error in function 'judge' (Give an alignment point to Player)\n"
				,"Player $arg1 does not exist.\n";
		} else {
			$arg2 = ($arg2 >= 1);
			sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
		}

	} elsif ($switch eq "kick") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			print	"Error in function 'kick' (Kick from Chat)\n"
				,"You are not in a Chat Room.\n";
		} elsif ($arg1 eq "") {
			print	"Syntax Error in function 'kick' (Kick from Chat)\n"
				,"Usage: kick <user #>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			print	"Error in function 'kick' (Kick from Chat)\n"
				,"Chat Room User $arg1 doesn't exist\n";
		} else {
			sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "leave") {
		if ($currentChatRoom eq "") {
			print	"Error in function 'leave' (Leave Chat Room)\n"
				,"You are not in a Chat Room.\n";
		} else {
			sendChatRoomLeave(\$remote_socket);
		}

	} elsif ($switch eq "look") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'look' (Look a Direction)\n"
				,"Usage: look <body dir> [<head dir>]\n";
		} else {
			look($arg1, $arg2);
		}

	} elsif ($switch eq "memo") {
		sendMemo(\$remote_socket);

	} elsif ($switch eq "ml") {
		$~ = "MLIST";
		print	"-----------Monster List ( Coordinate : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'} ) -----------\n"
			,"#    Name                     DmgTo    DmgFrom     (x,y)\n";
		for ($i = 0; $i < @monstersID; $i++) {
			next if ($monstersID[$i] eq "");
			$dmgTo = ($monsters{$monstersID[$i]}{'dmgTo'} ne "")
				? $monsters{$monstersID[$i]}{'dmgTo'}
				: 0;
			$dmgFrom = ($monsters{$monstersID[$i]}{'dmgFrom'} ne "")
				? $monsters{$monstersID[$i]}{'dmgFrom'}
				: 0;
			$type = "($monsters{$monstersID[$i]}{'pos_to'}{'x'},$monsters{$monstersID[$i]}{'pos_to'}{'y'})";
			format MLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<    @<<<<    @<<<<<<<<<<
$i   $monsters{$monstersID[$i]}{'name'}                 $dmgTo   $dmgFrom    $type
.
			write;
		}
		print "-------------------------------------------------------------\n";

	} elsif ($switch eq "move") {
		($arg1, $arg2, $arg3) = $input =~ /^[\s\S]*? (\d+) (\d+)(.*?)$/;
		
		undef $ai_v{'temp'}{'map'};
		if ($arg1 eq "") {
			($ai_v{'temp'}{'map'}) = $input =~ /^[\s\S]*? (.*?)$/;
		} else {
			$ai_v{'temp'}{'map'} = $arg3;
		}
		$ai_v{'temp'}{'map'} =~ s/\s//g;
		if (($arg1 eq "" || $arg2 eq "") && !$ai_v{'temp'}{'map'}) {
			print	"Syntax Error in function 'move' (Move Player)\n"
				,"Usage: move <x> <y> &| <map>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "stop") {
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			print "Stopped all movement\n";
		} else {
			$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
			if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
				if ($arg2 ne "") {
					print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $arg1, $arg2\n";
					$ai_v{'temp'}{'x'} = $arg1;
					$ai_v{'temp'}{'y'} = $arg2;
				} else {
					print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "Map $ai_v{'temp'}{'map'} does not exist\n";
			}
		}
#Mod Start
# Murder Report
	} elsif ($switch eq "mr") {
		my (@printMonster,%sMonster,$totalmon);
		$~ = "MRL"; 
		print "\n------Murder Report------\n"; 
		$totalmon=0;
		open (TMPMONSTI, "logs\/$config{'username'}_Tmpmr.txt"); 
		while ($line = <TMPMONSTI>) { 
			@printMonster = split(/\n/, $line); 
			foreach $tMonster (@printMonster) { 
				$sMonster{$tMonster} = $sMonster{$tMonster} + 1; 
				$totalmon=$totalmon+1;
			} 
		} 
		foreach $key (sort keys %sMonster) { 
format MRL = 
@<<<<<<<<<<<<<<<<< @>>>>> 
$key $sMonster{$key} 
. 
write;
		}
		close (TMPMONSTI); 
		print "-------------------------\n"; 
		print "Total :: $totalmon\n";
		print "-------------------------\n"; 
	} elsif ($switch eq "mrc") { 
		if (-e "logs\/$config{'username'}_Tmpmr.txt") { unlink("logs\/$config{'username'}_Tmpmr.txt"); } 
		print "Murder Report Cleared\n"; 
#Mod Stop
	} elsif ($switch eq "nl") {
		$~ = "NLIST";
		print	"-----------NPC List-----------\n"
			,"#    Name                         Coordinates\n";
		for ($i = 0; $i < @npcsID; $i++) {
			next if ($npcsID[$i] eq "");
			$ai_v{'temp'}{'pos_string'} = "($npcs{$npcsID[$i]}{'pos'}{'x'}, $npcs{$npcsID[$i]}{'pos'}{'y'})";
			format NLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<   @<<<<<<<<
$i   $npcs{$npcsID[$i]}{'name'} $ai_v{'temp'}{'pos_string'}   $npcs{$npcsID[$i]}{'nameID'}
.
			write;
		}
		print "---------------------------------\n";

	} elsif ($switch eq "p") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'p' (Party Chat)\n"
				,"Usage: p <message>\n";
		} else {
			sendMessage(\$remote_socket, "p", $arg1);
		}

	} elsif ($switch eq "party") {
		($arg1) = $input =~ /^[\s\S]*? (\w*)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
		if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party' (Party Functions)\n"
				,"Can't list party - you're not in a party.\n";
		} elsif ($arg1 eq "") {
			print "----------Party-----------\n";
			print $chars[$config{'char'}]{'party'}{'name'}."\n";
			$~ = "PARTYUSERS";
			print "#      Name                  Map                    Online    HP\n";
			for ($i = 0; $i < @partyUsersID; $i++) {
				next if ($partyUsersID[$i] eq "");
				$coord_string = "";
				$hp_string = "";
				$name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
				$admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? "(A)" : "";
				
				if ($partyUsersID[$i] eq $accountID) {
					$online_string = "Yes";
					($map_string) = $map_name =~ /([\s\S]*)\.gat/;
					$coord_string = $chars[$config{'char'}]{'pos'}{'x'}. ", ".$chars[$config{'char'}]{'pos'}{'y'};
					$hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}
							." (".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
							."%)";
				} else {
					$online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? "Yes" : "No";
					($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
					$coord_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}
						. ", ".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'}
						if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'} ne ""
							&& $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
					$hp_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}."/".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'}
							." (".int($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} * 100)
							."%)" if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
				}
				format PARTYUSERS = 
@< @<< @<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<< @<<       @<<<<<<<<<<<<<<<<<<
$i $admin_string $name_string $map_string  $coord_string $online_string $hp_string
.
				write;
			}
			print "--------------------------\n";
			
		} elsif ($arg1 eq "create") {
			($arg2) = $input =~ /^[\s\S]*? [\s\S]*? \"([\s\S]*?)\"/;
			if ($arg2 eq "") {
				print	"Syntax Error in function 'party create' (Organize Party)\n"
				,qq~Usage: party create "<party name>"\n~;
			} else {
				sendPartyOrganize(\$remote_socket, $arg2);
			}

		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			print	"Syntax Error in function 'party join' (Accept/Deny Party Join Request)\n"
				,"Usage: party join <flag>\n";
		} elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
			print	"Error in function 'party join' (Join/Request to Join Party)\n"
				,"Can't accept/deny party request - no incoming request.\n";
		} elsif ($arg1 eq "join") {
			sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
			undef %incomingParty;

		} elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party request' (Request to Join Party)\n"
				,"Can't request a join - you're not in a party.\n";
		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			print	"Error in function 'party request' (Request to Join Party)\n"
				,"Can't request to join party - player $arg2 does not exist.\n";
		} elsif ($arg1 eq "request") {
			sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);


		} elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party leave' (Leave Party)\n"
				,"Can't leave party - you're not in a party.\n";
		} elsif ($arg1 eq "leave") {
			sendPartyLeave(\$remote_socket);


		} elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party share' (Set Party Share EXP)\n"
				,"Can't set share - you're not in a party.\n";
		} elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
			print	"Syntax Error in function 'party share' (Set Party Share EXP)\n"
				,"Usage: party share <flag>\n";
		} elsif ($arg1 eq "share") {
			sendPartyShareEXP(\$remote_socket, $arg2);


		} elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party kick' (Kick Party Member)\n"
				,"Can't kick member - you're not in a party.\n";
		} elsif ($arg1 eq "kick" && $arg2 eq "") {
			print	"Syntax Error in function 'party kick' (Kick Party Member)\n"
				,"Usage: party kick <party member #>\n";
		} elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
			print	"Error in function 'party kick' (Kick Party Member)\n"
				,"Can't kick member - member $arg2 doesn't exist.\n";
		} elsif ($arg1 eq "kick") {
			sendPartyKick(\$remote_socket, $partyUsersID[$arg2]
					,$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});

		}
#mod Start
# Pet Function Add-on
	} elsif ($switch eq "pet") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ( $arg1 eq "info" || $arg1 eq "") {
			print "----- Pet Info -----\n";
			format PETINFO =
Pet Name : @<<<<<<<<<    Pet Lv : @<<
$chars[$config{'char'}]{'pet'}{'name'} $chars[$config{'char'}]{'pet'}{'level'}
Pet Hungry : @<<<<<<<<<  Pet Relation : @<<<
$chars[$config{'char'}]{'pet'}{'hungry'} $chars[$config{'char'}]{'pet'}{'friendly'}
.
			$~ = "PETINFO";
			write;
			print "--------------------\n";
		}elsif ( $arg1 eq "feed"){
			my $petfood = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'petAutoFood'});
			if ($petfood ne ""){
				sendPetCommand(\$remote_socket,1);
				print " You're feeding your pet \n";
			}else{
				print "You can't give : ".$config{'petAutoFood'}."\n";
			}
		}elsif ( $arg1 eq "play"){
			sendPetCommand(\$remote_socket,2);
			print " You're Playing your pet \n";
		}elsif ( $arg1 eq "back"){
			sendPetCommand(\$remote_socket,3);
			print " Your pet turning to Eggs\n";
		}else{
			print "Syntax Error in function 'pet' ( Q'pet command )\n"
			,"Usage : pet < info | feed | play | back >";
		}
#mod Stop
	} elsif ($switch eq "petl") {
		$~ = "PETLIST";
		print	"-----------Pet List-----------\n"
			,"#    Type                     Name\n";
		for ($i = 0; $i < @petsID; $i++) {
			next if ($petsID[$i] eq "");
			format PETLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<
$i   $pets{$petsID[$i]}{'name'} $pets{$petsID[$i]}{'name_given'}
.
			write;
		}
		print "----------------------------------\n";

	} elsif ($switch eq "pm") {
		($arg1, $arg2) =$input =~ /^[\s\S]*? "([\s\S]*?)" ([\s\S]*)/;
		$type = 0;
		if (!$arg1) {
			($arg1, $arg2) =$input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
			$type = 1;
		}
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'pm' (Private Message)\n"
				,qq~Usage: pm ("<username>" | <pm #>) <message>\n~;
		} elsif ($type) {
			if ($arg1 - 1 >= @privMsgUsers) {
				print	"Error in function 'pm' (Private Message)\n"
				,"Quick look-up $arg1 does not exist\n";
			} else {
				sendMessage(\$remote_socket, "pm", $arg2, $privMsgUsers[$arg1 - 1]);
				$lastpm{'msg'} = $arg2;
				$lastpm{'user'} = $privMsgUsers[$arg1 - 1];
			}
		} else {
			if ($arg1 =~ /^%(\d*)$/) {
				$arg1 = $1;
			}
#pml bugfix - chobit andy 20030127
			if (binFind(\@privMsgUsers, $arg1) eq "") {
				$privMsgUsers[@privMsgUsers] = $arg1;
			}
			sendMessage(\$remote_socket, "pm", $arg2, $arg1);
			$lastpm{'msg'} = $arg2;
			$lastpm{'user'} = $arg1;
		}

	} elsif ($switch eq "pml") {
		$~ = "PMLIST";
		print "-----------PM LIST-----------\n";
		for ($i = 1; $i <= @privMsgUsers; $i++) {
			format PMLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<
$i   $privMsgUsers[$i - 1]
.
			write;
		}
		print "-----------------------------\n";


	} elsif ($switch eq "pl") {
		$~ = "PLIST";
		print	"-----------Player List ( Coordinate : $chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'} ) -----------\n"
			,"#    Name                                 Sex   Job      (x,y)\n";
		for ($i = 0; $i < @playersID; $i++) {
			next if ($playersID[$i] eq "");
			if (%{$players{$playersID[$i]}{'guild'}}) {
				$name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
			} else {
				$name = $players{$playersID[$i]}{'name'};
			}
			$type = "($players{$playersID[$i]}{'pos_to'}{'x'}, $players{$playersID[$i]}{'pos_to'}{'y'})";
			format PLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<< @<<<<<<< @<<<<<<<<<
$i   $name $sex_lut{$players{$playersID[$i]}{'sex'}} $jobs_lut{$players{$playersID[$i]}{'jobID'}} $type
.
			write;
		}
		print "------------------------------------------------------------\n";

	} elsif ($switch eq "portals") {
		$~ = "PORTALLIST";
		print	"-----------Portal List-----------\n"
			,"#    Name                                Coordinates\n";
		for ($i = 0; $i < @portalsID; $i++) {
			next if ($portalsID[$i] eq "");
			$coords = "($portals{$portalsID[$i]}{'pos'}{'x'},$portals{$portalsID[$i]}{'pos'}{'y'})";
			format PORTALLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
$i   $portals{$portalsID[$i]}{'name'}    $coords
.
			write;
		}
		print "---------------------------------\n";

	} elsif ($switch eq "quit") {
		quit();
	
	} elsif ($switch eq "reload") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		parseReload($arg1);

	} elsif ($switch eq "relog") {
		relog();
#mod Start
#remaining time
	} elsif ($switch eq "remain") {
		print	"----------- Airtime Remaining -----------\n";
		$~ = "REMAIN";
		format REMAIN =
Day: @<< Hour: @<< Minutes: @<<
$chars[$config{'char'}]{'Airtime'}{'day'} $chars[$config{'char'}]{'Airtime'}{'hour'} $chars[$config{'char'}]{'Airtime'}{'minute'}
Login at: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'Airtime'}{'loginat'}
.
		write;
		print	"-----------------------------------------\n"
#mod Stop
	} elsif ($switch eq "respawn") {
		useTeleport(2);
#mod Start
# Force StorageAuto & SellAuto
		if ($config{'storageAuto'}) {
			shift @ai_seq;
			shift @ai_seq_args;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}elsif ($config{'sellAuto'}){
			shift @ai_seq;
			shift @ai_seq_args;
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		}
#mod Stop
	} elsif ($switch eq "s") {
		if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'}) {
			$baseEXPKill = $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
		} elsif ($chars[$config{'char'}]{'exp_last'} == 0 && $chars[$config{'char'}]{'exp_max_last'} == 0) {
			$baseEXPKill = 0;
		} else {
			$baseEXPKill = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
		}
		if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'}) {
			$jobEXPKill = $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
		} elsif ($chars[$config{'char'}]{'exp_job_last'} == 0 && $chars[$config{'char'}]{'exp_job_max_last'} == 0) {
			$jobEXPKill = 0;
		} else {
			$jobEXPKill = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
		}
		$hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}." ("
				.int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'hp_max'};
		$sp_string = $chars[$config{'char'}]{'sp'}."/".$chars[$config{'char'}]{'sp_max'}." ("
				.int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'sp_max'};
		$base_string = $chars[$config{'char'}]{'exp'}."/".$chars[$config{'char'}]{'exp_max'}." /$baseEXPKill ("
				.sprintf("%.2f",$chars[$config{'char'}]{'exp'}/$chars[$config{'char'}]{'exp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'exp_max'};
		$job_string = $chars[$config{'char'}]{'exp_job'}."/".$chars[$config{'char'}]{'exp_job_max'}." /$jobEXPKill ("
				.sprintf("%.2f",$chars[$config{'char'}]{'exp_job'}/$chars[$config{'char'}]{'exp_job_max'} * 100)
				."%)" if $chars[$config{'char'}]{'exp_job_max'};
		$weight_string = $chars[$config{'char'}]{'weight'}."/".$chars[$config{'char'}]{'weight_max'}." ("
				.int($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'} * 100)
				."%)" if $chars[$config{'char'}]{'weight_max'};
		$job_name_string = "$jobs_lut{$chars[$config{'char'}]{'jobID'}} $sex_lut{$chars[$config{'char'}]{'sex'}}";
		$id = unpack("L1",$accountID);
		print	"----------- Status ( GID: ",$id," ) --------\n";
		$~ = "STATUS";
		format STATUS =
@<<<<<<<<<<<<<<<<<<<<<<<< HP: @<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'name'} $hp_string
@<<<<<<<<<<<<<<<<<<<<<<<< SP: @<<<<<<<<<<<<<<<<<<
$job_name_string              $sp_string
Base: @<< @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      $chars[$config{'char'}]{'lv'} $base_string
Job:  @<< @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      $chars[$config{'char'}]{'lv_job'} $job_string
Weight: @>>>>>>>>>>>>>>>> Zenny: @<<<<<<<<<<<<<<
        $weight_string           $chars[$config{'char'}]{'zenny'}
Status: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'skillST'}
.
		write;
		print	"-------------------------------------","-" x length($id),"\n";


	} elsif ($switch eq "sell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetSellList(\$remote_socket, $talk{'ID'});

		} elsif ($arg1 eq "") {
			print	"Syntax Error in function 'sell' (Sell Inventory Item)\n"
				,"Usage: sell <item #> [<amount>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'sell' (Sell Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "send") {
		($args) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		sendRaw(\$remote_socket, $args);

	} elsif ($switch eq "sit") {
		$ai_v{'attackAuto_old'} = $config{'attackAuto'};
		$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
		configModify("attackAuto", 1);
		configModify("route_randomWalk", 0);
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
		sit();
		$ai_v{'sitAuto_forceStop'} = 0;

	} elsif ($switch eq "sm") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'sm' (Use Skill on Monster)\n"
				,"Usage: sm <skill #> <monster #> [<skill lvl>]\n";
		} elsif ($monstersID[$arg2] eq "") {
			print	"Error in function 'sm' (Use Skill on Monster)\n"
				,"Monster $arg2 does not exist.\n";	
		} elsif ($skillsID[$arg1] eq "") {
			print	"Error in function 'sm' (Use Skill on Monster)\n"
				,"Skill $arg1 does not exist.\n";
		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monstersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monsters{$monstersID[$arg2]}{'pos_to'}{'x'}, $monsters{$monstersID[$arg2]}{'pos_to'}{'y'});
			}
		}
	} elsif ($switch eq "shop"){
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "" || $arg1 eq "info") {
			if ($ai_v{'temp'}{'shopOpen'}){
				$~ = "ARTICLESLIST2"; 
				print "---------- $shop{'shop_title'} -------------\n"; 
				print "#  Name                          Type     Amount      Price\n";
				for ($i = 0; $i < @articles; $i++) {
					next if ($articles[$i] eq "");
					format ARTICLESLIST2 = 
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>>> @>>>>>>>>>z
$i $articles[$i]{'name'} $itemTypes_lut{$articles[$i]{'type'}} $articles[$i]{'amount'} $articles[$i]{'price'} 
. 
					write; 
				}
				print "-------------------------","-"x length($shop{'shop_title'}),"\n"; 
				print "You have earned : $shop{'earned'}z.\n";
				print "-------------------------","-"x length($shop{'shop_title'}),"\n"; 
			}else{
				print "Your Shop Status : Closed\n";
			}
		}elsif ($arg1 eq "open"){
			openShop(\$remote_socket);
		}elsif ($arg1 eq "close"){
			closeShop(\$remote_socket);
		}else {
			print	"Syntax Error in function 'shop' (Show Shop Detail)\n"
			,"Usage: shop [<info|open|close>]\n";
		}
	} elsif ($switch eq "skills") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "SKILLS";
			print "----------Skill List-----------\n";
			print "#  Skill Name                    Lv     SP\n";
			for ($i=0; $i < @skillsID; $i++) {
				format SKILLS =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<    @<<<
$i $skills_lut{$skillsID[$i]} $chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'} $skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}}
.
				write;
			}
			print "\nSkill Points: $chars[$config{'char'}]{'points_skill'}\n";
			print "-------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
			print	"Error in function 'skills add' (Add Skill Point)\n"
				,"Skill $arg2 does not exist.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'points_skill'} < 1) {
			print	"Error in function 'skills add' (Add Skill Point)\n"
				,"Not enough skill points to increase $skills_lut{$skillsID[$arg2]}.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});
		} else {
			print	"Syntax Error in function 'skills' (Skills Functions)\n"
				,"Usage: skills [<add>] [<skill #>]\n";
		}


	} elsif ($switch eq "sp") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'sp' (Use Skill on Player)\n"
				,"Usage: sp <skill #> <player #> [<skill lvl>]\n";
		} elsif ($playersID[$arg2] eq "") {
			print	"Error in function 'sp' (Use Skill on Player)\n"
				,"Player $arg2 does not exist.\n";	
		} elsif ($skillsID[$arg1] eq "") {
			print	"Error in function 'sp' (Use Skill on Player)\n"
				,"Skill $arg1 does not exist.\n";
		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $playersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $players{$playersID[$arg2]}{'pos_to'}{'x'}, $players{$playersID[$arg2]}{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "ss") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'ss' (Use Skill on Self)\n"
				,"Usage: ss <skill #> [<skill lvl>]\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"Error in function 'ss' (Use Skill on Self)\n"
				,"Skill $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg2 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "st") {
		print	"----------- Char Stats -----------\n";
		$~ = "STATS";
		$tilde = "~";
		format STATS =
Str: @<<+@<< #@< Atk:  @<<+@<< Def:  @<<+@<<
$chars[$config{'char'}]{'str'} $chars[$config{'char'}]{'str_bonus'} $chars[$config{'char'}]{'points_str'} $chars[$config{'char'}]{'attack'} $chars[$config{'char'}]{'attack_bonus'} $chars[$config{'char'}]{'def'} $chars[$config{'char'}]{'def_bonus'}
Agi: @<<+@<< #@< Matk: @<<@@<< Mdef: @<<+@<<
$chars[$config{'char'}]{'agi'} $chars[$config{'char'}]{'agi_bonus'} $chars[$config{'char'}]{'points_agi'} $chars[$config{'char'}]{'attack_magic_min'} $tilde $chars[$config{'char'}]{'attack_magic_max'} $chars[$config{'char'}]{'def_magic'} $chars[$config{'char'}]{'def_magic_bonus'}
Vit: @<<+@<< #@< Hit:  @<<     Flee: @<<+@<<
$chars[$config{'char'}]{'vit'} $chars[$config{'char'}]{'vit_bonus'} $chars[$config{'char'}]{'points_vit'} $chars[$config{'char'}]{'hit'} $chars[$config{'char'}]{'flee'} $chars[$config{'char'}]{'flee_bonus'}
Int: @<<+@<< #@< Critical: @<< Aspd: @<<
$chars[$config{'char'}]{'int'} $chars[$config{'char'}]{'int_bonus'} $chars[$config{'char'}]{'points_int'} $chars[$config{'char'}]{'critical'} $chars[$config{'char'}]{'attack_speed'}
Dex: @<<+@<< #@< Status Points: @<<
$chars[$config{'char'}]{'dex'} $chars[$config{'char'}]{'dex_bonus'} $chars[$config{'char'}]{'points_dex'} $chars[$config{'char'}]{'points_free'}
Luk: @<<+@<< #@< Guild: @<<<<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'luk'} $chars[$config{'char'}]{'luk_bonus'} $chars[$config{'char'}]{'points_luk'} $chars[$config{'char'}]{'guild'}{'name'}
.
		write;
		print	"----------------------------------\n";

	} elsif ($switch eq "stand") {
		if ($ai_v{'attackAuto_old'} ne "") {
			configModify("attackAuto", $ai_v{'attackAuto_old'});
			configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
		}
		stand();
		$ai_v{'sitAuto_forceStop'} = 1;

	} elsif ($switch eq "stat_add") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
		if ($arg1 ne "str" &&  $arg1 ne "agi" && $arg1 ne "vit" && $arg1 ne "int" 
			&& $arg1 ne "dex" && $arg1 ne "luk") {
			print	"Syntax Error in function 'stat_add' (Add Status Point)\n"
			,"Usage: stat_add <str | agi | vit | int | dex | luk>\n";
		} else {
			if ($arg1 eq "str") {
				$ID = 0x0D;
			} elsif ($arg1 eq "agi") {
				$ID = 0x0E;
			} elsif ($arg1 eq "vit") {
				$ID = 0x0F;
			} elsif ($arg1 eq "int") {
				$ID = 0x10;
			} elsif ($arg1 eq "dex") {
				$ID = 0x11;
			} elsif ($arg1 eq "luk") {
				$ID = 0x12;
			}
			if ($chars[$config{'char'}]{"points_$arg1"} > $chars[$config{'char'}]{'points_free'}) {
				print	"Error in function 'stat_add' (Add Status Point)\n"
					,"Not enough status points to increase $arg1\n";
			} else {
				$chars[$config{'char'}]{$arg1} += 1;
				sendAddStatusPoint(\$remote_socket, $ID);
			}
		}

	} elsif ($switch eq "storage") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "STORAGELIST";
			print "----------Storage-----------\n";
			print "#  Name\n";
			for ($i=0; $i < @storageID;$i++) {
				next if ($storageID[$i] eq "");
				$display = "$storage{$storageID[$i]}{'name'} x $storage{$storageID[$i]}{'amount'}";
				format STORAGELIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i $display                
.
				write;
			}
			print "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
			print "-------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			print	"Error in function 'storage add' (Add Item to Storage)\n"
				,"Inventory Item $arg2 does not exist\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && $storageID[$arg2] eq "") {
			print	"Error in function 'storage get' (Get Item from Storage)\n"
				,"Storage Item $arg2 does not exist\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $storage{$storageID[$arg2]}{'amount'}) {
				$arg3 = $storage{$storageID[$arg2]}{'amount'};
			}
			sendStorageGet(\$remote_socket, $storage{$storageID[$arg2]}{'index'}, $arg3);

		} elsif ($arg1 eq "close") {
			sendStorageClose(\$remote_socket);

		} else {
			print	"Syntax Error in function 'storage' (Storage Functions)\n"
				,"Usage: storage [<add | get | close>] [<inventory # | storage #>] [<amount>]\n";
		}

	} elsif ($switch eq "store") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$talk{'buyOrSell'}) {
			$~ = "STORELIST";
			print "----------Store List-----------\n";
			print "#  Name                    Type           Price\n";
			for ($i=0; $i < @storeList;$i++) {
				$display = $storeList[$i]{'name'};
				format STORELIST =
@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>>>z
$i $display                $itemTypes_lut{$storeList[$i]{'type'}} $storeList[$i]{'price'}
.
				write;
			}
			print "-------------------------------\n";
		} elsif ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetStoreList(\$remote_socket, $talk{'ID'});
		}

	} elsif ($switch eq "take") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'take' (Take Item)\n"
				,"Usage: take <item #>\n";
		} elsif ($itemsID[$arg1] eq "") {
			print	"Error in function 'take' (Take Item)\n"
				,"Item $arg1 does not exist.\n";
		} else {
			take($itemsID[$arg1]);
		}


	} elsif ($switch eq "talk") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;

		if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
			print	"Error in function 'talk' (Talk to NPC)\n"
				,"NPC $arg1 does not exist\n";
		} elsif ($arg1 =~ /^\d+$/) {
			sendTalk(\$remote_socket, $npcsID[$arg1]);

		} elsif ($arg1 eq "resp" && !%talk) {
			print	"Error in function 'talk resp' (Respond to NPC)\n"
				,"You are not talking to any NPC.\n";
		} elsif ($arg1 eq "resp" && $arg2 eq "") {
			$display = $npcs{$talk{'nameID'}}{'name'};
			$~ = "RESPONSES";
			print "----------Responses-----------\n";
			print "NPC: $display\n";
			print "#  Response\n";
			for ($i=0; $i < @{$talk{'responses'}};$i++) {
				format RESPONSES =
@< @<<<<<<<<<<<<<<<<<<<<<<
$i $talk{'responses'}[$i]
.
				write;
			}
			print "-------------------------------\n";
		} elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
			print	"Error in function 'talk resp' (Respond to NPC)\n"
				,"Response $arg2 does not exist.\n";
		} elsif ($arg1 eq "resp" && $arg2 ne "") {
			if ($talk{'responses'}[$arg2] eq "Cancel Chat") {
				$arg2 = 255;
			} else {
				$arg2 += 1;
			}
			sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);


		} elsif ($arg1 eq "cont" && !%talk) {
			print	"Error in function 'talk cont' (Continue Talking to NPC)\n"
				,"You are not talking to any NPC.\n";
		} elsif ($arg1 eq "cont") {
			sendTalkContinue(\$remote_socket, $talk{'ID'});


		} elsif ($arg1 eq "no") {
			sendTalkCancel(\$remote_socket, $talk{'ID'});


		} else {
			print	"Syntax Error in function 'talk' (Talk to NPC)\n"
				,"Usage: talk <NPC # | cont | resp> [<response #>]\n";
		}

	} elsif ($switch eq "tank") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'tank' (Tank for a Player)\n"
				,"Usage: tank <player #>\n";
		} elsif ($arg1 eq "stop") {
			configModify("tankMode", 0);
		} elsif ($playersID[$arg1] eq "") {
			print	"Error in function 'tank' (Tank for a Player)\n"
				,"Player $arg1 does not exist.\n";
		} else {
			configModify("tankMode", 1);
			configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
		}

	} elsif ($switch eq "tele") {
		useTeleport(1);

	} elsif ($switch eq "timeout") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'timeout' (set a timeout)\n"
				,"Usage: timeout <type> [<seconds>]\n";
		} elsif ($timeout{$arg1} eq "") {
			print	"Error in function 'timeout' (set a timeout)\n"
				,"Timeout $arg1 doesn't exist\n";
		} elsif ($arg2 eq "") {
			print "Timeout '$arg1' is $config{$arg1}\n";
		} else {
			setTimeout($arg1, $arg2);
		}


	} elsif ($switch eq "uneq") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'unequip' (Unequip Inventory Item)\n"
				,"Usage: unequip <item #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'unequip' (Unequip Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} == 0) {
			print	"Error in function 'unequip' (Unequip Inventory Item)\n"
				,"Inventory Item $arg1 is not equipped.\n";
		} else {
			sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
		}
#mod Start
#Solos Vender
	} elsif ($switch eq "vender") {
		($arg1) = $input =~ /^.*? (\d+)/;
		($arg2) = $input =~ /^.*? \d+ (\d+)/;
		($arg3) = $input =~ /^.*? \d+ \d+ (\d+)/;
		if ($arg1 eq "") {
			print	 "Error in function 'vender' (Vender Shop)\n"
					,"Usage: vender <vender # | end> [<item #> <amount>]\n";
		} elsif ($arg1 eq "end") {
			undef @venderItemList;
			undef $venderID;
		} elsif ($venderListsID[$arg1] eq "") {
			print	 "Error in function 'vender' (Vender Shop)\n"
					,"Vender $arg1 does not exist.\n";
		} elsif ($arg2 eq "") {
			sendEnteringVender(\$remote_socket, $venderListsID[$arg1]);
		} elsif ($venderListsID[$arg1] ne $venderID) {
			print	 "Error in function 'vender' (Vender Shop)\n"
					,"Vender ID is wrong.\n";
		} else {
			if ($arg3 <= 0) {
				$arg3 = 1;
			}
			sendBuyVender(\$remote_socket, $arg2, $arg3);
		}

	} elsif ($switch eq "version"){
		print "---------------------------------------------------------------\n";
		print $versionText;
		print "---------------------------------------------------------------\n";

	} elsif ($switch eq "vl") {
		$~ = "VLIST";
		print	 "-----------Vender List-----------\n"
				,"#   Title                                Owner\n";
		for ($i = 0; $i < @venderListsID; $i++) {
			next if ($venderListsID[$i] eq "");
			$owner_string = ($venderListsID[$i] ne $accountID) ? $players{$venderListsID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
			format VLIST = 
@>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<
$i  $venderLists{$venderListsID[$i]}{'title'} $owner_string
.
			write;
		}
		print	"----------------------------------\n";
#mod Stop
	} elsif ($switch eq "where") {
#mod Start
		$oldmapdrt=0;
		($map_string) = $map_name =~ /([\s\S]*)\.gat/;
		print "------------------------------------\n";
		print "Location $maps_lut{$map_string.'.rsw'}($map_string) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n";
		print "Last destination calculated : (".int($old_x).", ".int($old_y).") from spot (".int($old_pos_x).", ".int($old_pos_y).").\n";
		print "------------------------------------\n";
#mod Stop

	} elsif ($switch eq "who") {
		sendWho(\$remote_socket);
	}
}



#######################################
#######################################
#AI
#######################################
#######################################



sub AI {
	
	my $i, $j;
	my %cmd = %{(shift)};
	if (%cmd) {
		$responseVars{'cmd_user'} = $cmd{'user'};
		if ($cmd{'user'} eq $chars[$config{'char'}]{'name'}) {
			return;
		}
 		if ($cmd{'type'} eq "pm" || $cmd{'type'} eq "p" || $cmd{'type'} eq "g") {
			$ai_v{'temp'}{'qm'} = quotemeta $config{'adminPassword'};
			if ($cmd{'msg'} =~ /^$ai_v{'temp'}{'qm'}\b/) {
				if ($overallAuth{$cmd{'user'}} == 1) {
					sendMessage(\$remote_socket, "pm", getResponse("authF"), $cmd{'user'});
				} else {
					auth($cmd{'user'}, 1);
					sendMessage(\$remote_socket, "pm", getResponse("authS"),$cmd{'user'});
				}
			}
		}
		$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
		if ($overallAuth{$cmd{'user'}} >= 1 
			&& ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")) {
			if ($cmd{'msg'} =~ /\bsit\b/i) {
				$ai_v{'sitAuto_forceStop'} = 0;
				$ai_v{'attackAuto_old'} = $config{'attackAuto'};
				$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
				configModify("attackAuto", 1);
				configModify("route_randomWalk", 0);
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				sit();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("sitS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bstand\b/i) {
				$ai_v{'sitAuto_forceStop'} = 1;
				if ($ai_v{'attackAuto_old'} ne "") {
					configModify("attackAuto", $ai_v{'attackAuto_old'});
					configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
				}
				stand();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("standS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\brelog\b/i) {
				relog();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("relogS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\blogout\b/i) {
				quit();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("quitS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\breload\b/i) {
				parseReload($');
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("reloadS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bstatus\b/i) {
				$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
				$responseVars{'char_hp'} = $chars[$config{'char'}]{'hp'};
				$responseVars{'char_sp_max'} = $chars[$config{'char'}]{'sp_max'};
				$responseVars{'char_hp_max'} = $chars[$config{'char'}]{'hp_max'};
				$responseVars{'char_lv'} = $chars[$config{'char'}]{'lv'};
				$responseVars{'char_lv_job'} = $chars[$config{'char'}]{'lv_job'};
				$responseVars{'char_exp'} = $chars[$config{'char'}]{'exp'};
				$responseVars{'char_exp_max'} = $chars[$config{'char'}]{'exp_max'};
				$responseVars{'char_exp_job'} = $chars[$config{'char'}]{'exp_job'};
				$responseVars{'char_exp_job_max'} = $chars[$config{'char'}]{'exp_job_max'};
				$responseVars{'char_weight'} = $chars[$config{'char'}]{'weight'};
				$responseVars{'char_weight_max'} = $chars[$config{'char'}]{'weight_max'};
				$responseVars{'zenny'} = $chars[$config{'char'}]{'zenny'};
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("statusS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bconf\b/i) {
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /(\w+) (\w+)/;
				@{$ai_v{'temp'}{'conf'}} = keys %config;
				if ($ai_v{'temp'}{'arg1'} eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $ai_v{'temp'}{'arg1'}) eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF2"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($ai_v{'temp'}{'arg2'} eq "value") {
					if ($ai_v{'temp'}{'arg1'} =~ /username/i || $ai_v{'temp'}{'arg1'} =~ /password/i) {
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF3"), $cmd{'user'}) if $config{'verbose'};
					} else {
						$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
						$responseVars{'value'} = $config{$ai_v{'temp'}{'arg1'}};
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS1"), $cmd{'user'}) if $config{'verbose'};
						$timeout{'ai_thanks_set'}{'time'} = time;
					}
				} else {
					configModify($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS2"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\btimeout\b/i) {
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /([\s\S]+) (\w+)/;
				if ($ai_v{'temp'}{'arg1'} eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($timeout{$ai_v{'temp'}{'arg1'}} eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF2"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($ai_v{'temp'}{'arg2'} eq "") {
					$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
					$responseVars{'value'} = $timeout{$ai_v{'temp'}{'arg1'}};
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS1"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					setTimeout($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS2"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\bshut[\s\S]*up\b/i) {
				if ($config{'verbose'}) {
					configModify("verbose", 0);
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffS"), $cmd{'user'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffF"), $cmd{'user'});
				}
			} elsif ($cmd{'msg'} =~ /\bspeak\b/i) {
				if (!$config{'verbose'}) {
					configModify("verbose", 1);
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnS"), $cmd{'user'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnF"), $cmd{'user'});
				}
			} elsif ($cmd{'msg'} =~ /\bdate\b/i) {
				$responseVars{'date'} = getFormattedDate(int(time));
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("dateS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bmove\b/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bmove\b/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, $ai_v{'temp'}{'arg3'}) = $ai_v{'temp'}{'after'} =~ /(\d+)\D+(\d+)(.*?)$/;
				undef $ai_v{'temp'}{'map'};
				if ($ai_v{'temp'}{'arg1'} eq "") {
					($ai_v{'temp'}{'map'}) = $ai_v{'temp'}{'after'} =~ /(.*?)$/;
				} else {
					$ai_v{'temp'}{'map'} = $ai_v{'temp'}{'arg3'};
				}
				$ai_v{'temp'}{'map'} =~ s/\s//g;
				if (($ai_v{'temp'}{'arg1'} eq "" || $ai_v{'temp'}{'arg2'} eq "") && !$ai_v{'temp'}{'map'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
				} else {
					$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
					if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
						if ($ai_v{'temp'}{'arg2'} ne "") {
							print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}\n";
							$ai_v{'temp'}{'x'} = $ai_v{'temp'}{'arg1'};
							$ai_v{'temp'}{'y'} = $ai_v{'temp'}{'arg2'};
						} else {
							print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
							undef $ai_v{'temp'}{'x'};
							undef $ai_v{'temp'}{'y'};
						}
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
						ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
						$timeout{'ai_thanks_set'}{'time'} = time;
					} else {
						print "Map $ai_v{'temp'}{'map'} does not exist\n";
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
					}
				}
			} elsif ($cmd{'msg'} =~ /\blook\b/i) {
				($ai_v{'temp'}{'body'}) = $cmd{'msg'} =~ /(\d+)/;
				($ai_v{'temp'}{'head'}) = $cmd{'msg'} =~ /\d+ (\d+)/;
				if ($ai_v{'temp'}{'body'} ne "") {
					look($ai_v{'temp'}{'body'}, $ai_v{'temp'}{'head'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookF"), $cmd{'user'}) if $config{'verbose'};
				}	

			} elsif ($cmd{'msg'} =~ /\bfollow/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				if ($config{'follow'}) {
					aiRemove("follow");
					configModify("follow", 0);
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\bfollow\b/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} ne "") {
					aiRemove("follow");
					ai_follow($players{$ai_v{'temp'}{'targetID'}}{'name'});
					configModify("follow", 1);
					configModify("followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\btank/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				if (!$config{'tankMode'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopF"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($config{'tankMode'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopS"), $cmd{'user'}) if $config{'verbose'};
					configModify("tankMode", 0);
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\btank/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} ne "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankS"), $cmd{'user'}) if $config{'verbose'};
					configModify("tankMode", 1);
					configModify("tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\btown/i) {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
				useTeleport(2);
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bwhere\b/i) {
				$responseVars{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
				$responseVars{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
				$responseVars{'map'} = qq~$maps_lut{$field{'name'}.'.rsw'} ($field{'name'})~;
				$timeout{'ai_thanks_set'}{'time'} = time;
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("whereS"), $cmd{'user'}) if $config{'verbose'};
			}
			
		}
		$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
		if ($overallAuth{$cmd{'user'}} >= 1 && ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")
			&& $cmd{'msg'} =~ /\bheal\b/i) {
			$ai_v{'temp'}{'after'} = $';
			($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
			$ai_v{'temp'}{'after'} =~ s/\d+//;
			$ai_v{'temp'}{'after'} =~ s/^\s+//;
			$ai_v{'temp'}{'after'} =~ s/\s+$//;
			$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
			if ($ai_v{'temp'}{'targetID'} eq "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
			} elsif ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
				undef $ai_v{'temp'}{'amount_healed'};
				undef $ai_v{'temp'}{'sp_needed'};
				undef $ai_v{'temp'}{'sp_used'};
				undef $ai_v{'temp'}{'failed'};
				undef @{$ai_v{'temp'}{'skillCasts'}};
				while ($ai_v{'temp'}{'amount_healed'} < $ai_v{'temp'}{'amount'}) {
					for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
						$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
						$ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
								* (4 + $i * 8);
						last if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $ai_v{'temp'}{'amount'});
					}
					$ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
					$ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
				}
				while ($ai_v{'temp'}{'sp_used'} < $ai_v{'temp'}{'sp_needed'} && !$ai_v{'temp'}{'failed'}) {
					for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
						$ai_v{'temp'}{'lv'} = $i;
						$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
						if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
							$ai_v{'temp'}{'lv'}--;
							$ai_v{'temp'}{'sp'} = 10 + ($ai_v{'temp'}{'lv'} * 3);
							last;
						}
						last if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} >= $ai_v{'temp'}{'sp_needed'});
					}
					if ($ai_v{'temp'}{'lv'} > 0) {
						$ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
						$ai_v{'temp'}{'skillCast'}{'skill'} = 28;
						$ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
						$ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
						$ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
						$ai_v{'temp'}{'skillCast'}{'ID'} = $ai_v{'temp'}{'targetID'};
						unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};
					} else {
						$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'} - $ai_v{'temp'}{'sp_used'};
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
						$ai_v{'temp'}{'failed'} = 1;
					}
				}
				if (!$ai_v{'temp'}{'failed'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
				foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
					ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'ID'});
				}
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
			}
		}

		if ($overallAuth{$cmd{'user'}} >= 1) {
			if ($cmd{'msg'} =~ /\bthank/i || $cmd{'msg'} =~ /\bthn/i) {
				if (!timeOut(\%{$timeout{'ai_thanks_set'}})) {
					$timeout{'ai_thanks_set'}{'time'} -= $timeout{'ai_thanks_set'}{'timeout'};
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("thankS"), $cmd{'user'}) if $config{'verbose'};
				}
			}
		}
#mod Start
# Chatauto part 1
		if ($config{'ChatAuto'} && !$ppllog{'talktime'}{'time'} 
			&& ($cmd{'msg'} ne $ppllog{'cmd'}{"$cmd{'user'}"}{'last'} && $cmd{'msg'} ne $ppllog{'emotion'}{'last'})
			&& ($ppllog{'cmd'}{"$cmd{'user'}"}{'resp'}<=$config{'ChatAuto_Max'})
			&& ( ($cmd{'type'} eq "c" && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$cmd{'ID'}}{'pos_to'}}) <= $config{'ChatAuto_Distance'})
			|| $cmd{'type'} eq "pm" || $cmd{'type'} eq "e" || $cmd{'type'} eq "C")
		){
			$ppllog{'cmd'}{"$cmd{'user'}"}{'ans'}= getResMsg($cmd{'msg'});
			if ($ppllog{'cmd'}{"$cmd{'user'}"}{'ans'} ne ""){
				$ppllog{'talktime'}{'timeout'} = ($ppllog{'cmd'}{"$cmd{'user'}"}{'ans'} =~ /^e \d+/) ? $config{'ChatAuto_Emotime'} : $config{'ChatAuto_Cps'}*length($ppllog{'cmd'}{"$cmd{'user'}"}{'ans'});
				$ppllog{'talktime'}{'time'}=time;
				$ppllog{'name'} = $cmd{'user'};
				$ppllog{'type'} = $cmd{'type'};
				if ($cmd{'type'} ne "e") {
					$ppllog{'cmd'}{"$cmd{'user'}"}{'last'} = $cmd{'msg'} if ($cmd{'msg'} !~ /^\//);
					$ppllog{'cmd'}{"$cmd{'user'}"}{'resp'}++;
					alertsound($config{'alertSound_name'},$config{'alertSound_volume'}) if ($config{'alertSound'} && $type eq "c" && !$ppllog{'cmd'}{"$cmd{'user'}"}{'resp'});
				}else{
					$ppllog{'emotion'}{'last'} = $cmd{'msg'};
				}
			}
			unshift @ai_seq, "chatauto";
			unshift @ai_seq_args, {};
		}elsif ($ppllog{'cmd'}{"$cmd{'user'}"}{'resp'}>$config{'ChatAuto_Max'} && $config{'ChatAuto_Autoignored'} && $cmd{'type'} eq "pm"){
			sendIgnore(\$remote_socket,$cmd{'user'}, 0);
		}
#mod Stop
	}

	
	##### MISC #####

	if (timeOut(\%{$timeout{'ai_wipe_check'}})) {
		foreach (keys %players_old) {
			delete $players_old{$_} if (time - $players_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %monsters_old) {
			delete $monsters_old{$_} if (time - $monsters_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %npcs_old) {
			delete $npcs_old{$_} if (time - $npcs_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %items_old) {
			delete $items_old{$_} if (time - $items_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %portals_old) {
			delete $portals_old{$_} if (time - $portals_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		$timeout{'ai_wipe_check'}{'time'} = time;
		print "Wiped old\n" if ($config{'debug'} >= 2);
	}

	if (timeOut(\%{$timeout{'ai_getInfo'}})) {
		foreach (keys %players) {
			if ($players{$_}{'name'} eq "Unknown") {
				sendGetPlayerInfo(\$remote_socket, $_);
				last if (!$config{'fastInfoDetect'});
			}
		}
		foreach (keys %monsters) {
			if ($monsters{$_}{'name'} =~ /Unknown/) {
				sendGetPlayerInfo(\$remote_socket, $_);
				last if (!$config{'fastInfoDetect'});
			}
		}
		foreach (keys %npcs) { 
			if ($npcs{$_}{'name'} =~ /Unknown/) { 
				sendGetPlayerInfo(\$remote_socket, $_); 
				last if (!$config{'fastInfoDetect'});
			}
		}
		foreach (keys %pets) { 
			if ($pets{$_}{'name_given'} =~ /Unknown/) { 
				sendGetPlayerInfo(\$remote_socket, $_); 
				last if (!$config{'fastInfoDetect'});
			}
		}
		$timeout{'ai_getInfo'}{'time'} = time;
	}

	if (timeOut(\%{$timeout{'ai_sync'}})) {
		$timeout{'ai_sync'}{'time'} = time;
		sendSync(\$remote_socket, getTickCount());
	}
	if ($ai_seq[0] eq "look" && timeOut(\%{$timeout{'ai_look'}})) {
		$timeout{'ai_look'}{'time'} = time;
		sendLook(\$remote_socket, $ai_seq_args[0]{'look_body'}, $ai_seq_args[0]{'look_head'});
		shift @ai_seq;
		shift @ai_seq_args;
	}

	if ($ai_seq[0] ne "deal" && %currentDeal) {
		unshift @ai_seq, "deal";
		unshift @ai_seq_args, "";
	} elsif ($ai_seq[0] eq "deal" && !%currentDeal) {
		shift @ai_seq;
		shift @ai_seq_args;
	}

	if ($config{'dealAutoCancel'} && %incomingDeal && timeOut(\%{$timeout{'ai_dealAutoCancel'}})) {
		sendDealCancel(\$remote_socket);
		$timeout{'ai_dealAutoCancel'}{'time'} = time;
	}
	if ($config{'partyAutoDeny'} && %incomingParty && timeOut(\%{$timeout{'ai_partyAutoDeny'}})) {
		sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, 0);
		$timeout{'ai_partyAutoDeny'}{'time'} = time;
		undef %incomingParty;
	}

	 if ($config{'guildAutoDeny'} && %incomingGuild && timeOut(\%{$timeout{'ai_guildAutoDeny'}})) {
		sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, 0) if ($incomingGuild{'Type'}==1);
		sendGuildAlly(\$remote_socket, $incomingGuild{'ID'}, 0) if ($incomingGuild{'Type'}==2);
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
		undef %incomingGuild;
	}

	if ($ai_v{'portalTrace_mapChanged'}) {
		undef $ai_v{'portalTrace_mapChanged'};
		$ai_v{'temp'}{'first'} = 1;
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};
		
		foreach (@portalsID_old) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars_old[$config{'char'}]{'pos_to'}}, \%{$portals_old{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_v{'portalTrace'}{'source'}{'map'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'source'}{'map'};
			$ai_v{'portalTrace'}{'source'}{'ID'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'nameID'};
			%{$ai_v{'portalTrace'}{'source'}{'pos'}} = %{$portals_old{$ai_v{'temp'}{'foundID'}}{'pos'}};
		}
	}

	if (%{$ai_v{'portalTrace'}} && portalExists($ai_v{'portalTrace'}{'source'}{'map'}, \%{$ai_v{'portalTrace'}{'source'}{'pos'}}) ne "") {
		undef %{$ai_v{'portalTrace'}};
	} elsif (%{$ai_v{'portalTrace'}} && $field{'name'}) {
		$ai_v{'temp'}{'first'} = 1;
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};
		
		foreach (@portalsID) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
			if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}
		
		if (%{$portals{$ai_v{'temp'}{'foundID'}}}) {
			if (portalExists($field{'name'}, \%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}) eq ""
				&& $ai_v{'portalTrace'}{'source'}{'map'} && $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} ne "" && $ai_v{'portalTrace'}{'source'}{'pos'}{'y'} ne ""
				&& $field{'name'} && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} ne "" && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'} ne "") {

				
				$portals{$ai_v{'temp'}{'foundID'}}{'name'} = "$field{'name'} -> $ai_v{'portalTrace'}{'source'}{'map'}";
				$portals{pack("L",$ai_v{'portalTrace'}{'source'}{'ID'})}{'name'} = "$ai_v{'portalTrace'}{'source'}{'map'} -> $field{'name'}";

				$ai_v{'temp'}{'ID'} = "$ai_v{'portalTrace'}{'source'}{'map'} $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} $ai_v{'portalTrace'}{'source'}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};

				updatePortalLUT("$def_table/portals.txt",
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'},
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'});

				$ai_v{'temp'}{'ID2'} = "$field{'name'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};

				updatePortalLUT("$def_table/portals.txt",
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'},
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'});
			}
			undef %{$ai_v{'portalTrace'}};
		}
	}

	##### CLIENT SUSPEND #####

	if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "clientSuspend") {
		#this section is used in X-Kore
	}

	#storageAuto - chobit aska 20030128
	#####AUTO STORAGE ( GET & KEEP )#####

	AUTOSTORAGE: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
#mod Start
# getAuto Part I
	}elsif (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && timeOut(\%{$timeout{'ai_storageAuto'}})) {
		undef $ai_v{'temp'}{'found'};
		$i = 0; 
		while (1) { 
			last if (!$config{"getAuto_$i"}); 
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"}); 
			if ($config{"getAuto_$i"."_minAmount"} ne "" && $config{"getAuto_$i"."_maxAmount"} ne "" && !$stockVoid[$i] 
				&& ($ai_v{'temp'}{'invIndex'} eq "" 
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"getAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"}))) { 
				$ai_v{'temp'}{'found'} = 1;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_storageAuto'}{'time'} = time;
#mod Stop
	}

	if ($ai_seq[0] eq "storageAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "storageAuto" && timeOut(\%{$timeout{'ai_storageAuto'}})) {
		if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTORAGE;
		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_storageAuto'}{'time'} = time;
			} else {
				print "Calculating auto-storage route to: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0,$config{'storageAuto_Distance'},1);
			}
		} else {
			if ($ai_seq_args[0]{'sentStore'} <= 1) {
				CheckStorageNPC();
				sendTalk(\$remote_socket, pack("L1",$config{'storageAuto_npc'})) if !$ai_seq_args[0]{'sentStore'};
				sendTalkContinue(\$remote_socket, pack("L1",$config{'storageAuto_npc'})) if !$ai_seq_args[0]{'sentStore'};
				sendTalkResponse(\$remote_socket, pack("L1",$config{'storageAuto_npc'}),'2') if !$ai_seq_args[0]{'sentStore'};
				$ai_seq_args[0]{'sentStore'}++;
				$timeout{'ai_storageAuto'}{'time'} = time;
				last AUTOSTORAGE;
			}
			$ai_seq_args[0]{'done'} = 1;
#mod Start
#getAuto Part II
			if (!$ai_seq_args[0]{'getStart'}) {
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
					if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
						&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
						if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
							&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}})) {
							last AUTOSTORAGE;
						} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
							$timeout{'ai_storageAuto_giveup'}{'time'} = time;
						}
						undef $ai_seq_args[0]{'done'};
						$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
						sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
						$timeout{'ai_storageAuto'}{'time'} = time;
						last AUTOSTORAGE;
					}
				}
			}
			
			if (!$ai_seq_args[0]{'getStart'} && $ai_seq_args[0]{'done'} == 1) {
				$ai_seq_args[0]{'getStart'} = 1;
				undef $ai_seq_args[0]{'done'};
				last AUTOSTORAGE; 
			}
			$i = 0;
			undef $ai_seq_args[0]{'index'};
			while (1) {
				last if (!$config{"getAuto_$i"});
				$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"});
				if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"getAuto_$i"."_maxAmount"} ne "" && !$stockVoid[$i] && ($ai_seq_args[0]{'invIndex'} eq ""
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"})) {
					$ai_seq_args[0]{'index'} = $i;
					last;
				}
				$i++;
			}
			if ($ai_seq_args[0]{'index'} eq ""
				|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
				&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}}))) {
					$ai_seq_args[0]{'done'} = 1;
					sendStorageClose(\$remote_socket);
					last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				$timeout{'ai_storageAuto_giveup'}{'time'} = time;
			}
			undef $ai_seq_args[0]{'done'};
			undef $ai_seq_args[0]{'storageInvID'};
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'}; 
			$ai_seq_args[0]{'storageInvID'} = findKeyString(\%storage, "name", $config{"getAuto_$ai_seq_args[0]{'index'}"}); 
			if ($ai_seq_args[0]{'storageInvID'} eq "") {
				$stockVoid[$ai_seq_args[0]{'index'}] = 1; 
				last AUTOSTORAGE; 
			} elsif ($ai_seq_args[0]{'invIndex'} ne "") { 
				if ($config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} > $storage{$ai_seq_args[0]{'storageInvID'}}{'amount'}) { 
					$getAmount = $storage{$ai_seq_args[0]{'storageInvID'}}{'amount'}; 
					$stockVoid[$ai_seq_args[0]{'index'}] = 1; 
				} else { 
					$getAmount = $config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'}; 
				} 
			} else {
				if ($config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} > $storage{$ai_seq_args[0]{'storageInvID'}}{'amount'}) { 
					$getAmount = $storage{$ai_seq_args[0]{'storageInvID'}}{'amount'}; 
					$stockVoid[$ai_seq_args[0]{'index'}] = 1; 
				} else { 
					$getAmount = $config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"}; 
				} 
			} 
			sendStorageGet(\$remote_socket, $storage{$ai_seq_args[0]{'storageInvID'}}{'index'}, $getAmount); 
			$timeout{'ai_storageAuto'}{'time'} = time;
#mod Stop
		}
	}

	} #END OF BLOCK AUTOSTORAGE


	#####AUTO SELL#####

	AUTOSELL: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'sellAuto'} && $config{'sellAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "sellAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "sellAuto" && timeOut(\%{$timeout{'ai_sellAuto'}})) {
		if (!$config{'sellAuto'} || !%{$npcs_lut{$config{'sellAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSELL;
		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_sellAuto'}{'time'} = time;
			} else {
				print "Calculating auto-sell route to: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if ($ai_seq_args[0]{'sentSell'} <= 1) {
				sendTalk(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if !$ai_seq_args[0]{'sentSell'};
				sendGetSellList(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
				$ai_seq_args[0]{'sentSell'}++;
				$timeout{'ai_sellAuto'}{'time'} = time;
				last AUTOSELL;
			}
			$ai_seq_args[0]{'done'} = 1;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
				if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
					&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
					if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
						&& timeOut(\%{$timeout{'ai_sellAuto_giveup'}})) {
						last AUTOSELL;
					} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
						$timeout{'ai_sellAuto_giveup'}{'time'} = time;
					}
					undef $ai_seq_args[0]{'done'};
					$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
					sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
					$timeout{'ai_sellAuto'}{'time'} = time;
					last AUTOSELL;
				}
			}
		}
	}

	} #END OF BLOCK AUTOSELL



	#####AUTO BUY#####

	AUTOBUY: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_buyAuto'}})) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while (1) {
			last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if ($config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne ""
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"}))) {
				$ai_v{'temp'}{'found'} = 1;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_buyAuto'}{'time'} = time;
	}

	if ($ai_seq[0] eq "buyAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "buyAuto" && timeOut(\%{$timeout{'ai_buyAuto_wait'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}})) {
		$i = 0;
		undef $ai_seq_args[0]{'index'};
		
		while (1) {
			last if (!$config{"buyAuto_$i"} || !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}});
			$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"buyAuto_$i"."_maxAmount"} ne "" && ($ai_seq_args[0]{'invIndex'} eq "" 
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {
				$ai_seq_args[0]{'index'} = $i;
				last;
			}
			$i++;
		}
		if ($ai_seq_args[0]{'index'} eq ""
			|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
			&& timeOut(\%{$timeout{'ai_buyAuto_giveup'}}))) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOBUY;
		}
		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;			
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
			} else {
				print qq~Calculating auto-buy route to: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}\n~;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				undef $ai_seq_args[0]{'itemID'};
				if ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} != $config{"buyAuto_$ai_seq_args[0]{'lastIndex'}"."_npc"}) {
					undef $ai_seq_args[0]{'sentBuy'};
				}
				$timeout{'ai_buyAuto_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			if ($ai_seq_args[0]{'itemID'} eq "") {
				foreach (keys %items_lut) {
					if (lc($items_lut{$_}) eq lc($config{"buyAuto_$ai_seq_args[0]{'index'}"})) {
						$ai_seq_args[0]{'itemID'} = $_;
					}
				}
				if ($ai_seq_args[0]{'itemID'} eq "") {
					$ai_seq_args[0]{'index_failed'}{$ai_seq_args[0]{'index'}} = 1;
					print "autoBuy index $ai_seq_args[0]{'index'} failed\n" if $config{'debug'};
					last AUTOBUY;
				}
			}

			if ($ai_seq_args[0]{'sentBuy'} <= 1) {
				sendTalk(\$remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if !$ai_seq_args[0]{'sentBuy'};
				sendGetStoreList(\$remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if $ai_seq_args[0]{'sentBuy'};
				$ai_seq_args[0]{'sentBuy'}++;
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
				last AUTOBUY;
			}	
			if ($ai_seq_args[0]{'invIndex'} ne "") {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'});
			} else {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"});
			}
			$timeout{'ai_buyAuto_wait_buy'}{'time'} = time;
		}
	}

	} #END OF BLOCK AUTOBUY

	##### LOCKMAP #####
	

	if ($ai_seq[0] eq "" && $config{'lockMap'} && $field{'name'} 
		&& ($field{'name'} ne $config{'lockMap'} || ($config{'lockMap_x'} ne "" && ($chars[$config{'char'}]{'pos_to'}{'x'} != $config{'lockMap_x'} || $chars[$config{'char'}]{'pos_to'}{'y'} != $config{'lockMap_y'})))) {
		if ($maps_lut{$config{'lockMap'}.'.rsw'} eq "") {
			print "Invalid map specified for lockMap - map $config{'lockMap'} doesn't exist\n";
		} else {
			if ($config{'lockMap_x'} ne "") {
				print "Calculating lockMap route to: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}): $config{'lockMap_x'}, $config{'lockMap_y'}\n";
			} else {
				print "Calculating lockMap route to: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n";
			}
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $config{'lockMap_x'}, $config{'lockMap_y'}, $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
		}
	}

#mod Start
	##### Shop AutoStart #####
	if ($ai_seq[0] eq "" && $shop{'shop_autoStart'} && !$ai_v{'temp'}{'shop'}{'time'} && !$ai_v{'temp'}{'shopOpen'}) {
		configModify("route_randomWalk",0) if ($config{'route_randomWalk'});
		configModify("makeChatwhenSit",0) if ($config{'makeChatwhenSit'});
		configModify("attackAuto",0) if ($config{'attackAuto'}>1);
		configModify("AvoidGM",0) if ($config{'AvoidGM'});
		unshift @ai_seq, "shopauto";
		unshift @ai_seq_args, {};
	}elsif ($ai_seq[0] eq "shopauto" && !$ai_v{'temp'}{'shop'}{'time'} && !$ai_v{'temp'}{'shopOpen'}){
		if ($chars[$config{'char'}]{'sitting'}) {
			sendStand(\$remote_socket); 
			sleep(0.5); 
		}
		$ai_v{'temp'}{'shop'}{'time'} = time;
	}elsif ($ai_seq[0] eq "shopauto" && !$ai_v{'temp'}{'shopOpen'} && timeOut($ai_v{'temp'}{'shop'}{'time'},$shop{'shop_startTimeDelay'})){
		openShop(\$remote_socket);
		undef $ai_v{'temp'}{'shop'}{'time'};
	}
#mod Stop

	##### RANDOM WALK #####
	if ($config{'route_randomWalk'} && $ai_seq[0] eq "" && @{$field{'field'}} > 1 && !$cities_lut{$field{'name'}.'.rsw'}) {
		do { 
			$ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
			$ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
		} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]);
#mod Start
#Asimov Fill Color
		$CONSOLE->Attr($FG_LIGHTCYAN|$BG_BLACK) if ($config{'colorMode'});
		print "Calculating random route to: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
#mod Stop
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
	}

	##### DEAD #####


	if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
		shift @ai_seq;
		shift @ai_seq_args;

		#force storage after death
		unshift @ai_seq, "storageAuto";
		unshift @ai_seq_args, {};
	} elsif ($ai_seq[0] ne "dead" && $chars[$config{'char'}]{'dead'}) {
		undef @ai_seq;
		undef @ai_seq_args;
		unshift @ai_seq, "dead";
		unshift @ai_seq_args, {};
	}
	
	if ($ai_seq[0] eq "dead" && time - $chars[$config{'char'}]{'dead_time'} >= $timeout{'ai_dead_respawn'}{'timeout'}) {
		sendRespawn(\$remote_socket);
		$chars[$config{'char'}]{'dead_time'} = time;
	}
	
	if ($ai_seq[0] eq "dead" && $config{'dcOnDeath'}) {
		print "Disconnecting on death!\n";
		$quit = 1;
	}


	##### AUTO-ITEM USE #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" 
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" 
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack")
		&& timeOut(\%{$timeout{'ai_item_use_auto'}})) { 
		$i = 0;
		while (1) {
			last if (!$config{"useSelf_item_$i"});
#mod Start
# Fix auto item use
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_sp_lower"}
				&& !($config{"useSelf_item_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
				&& $config{"useSelf_item_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"useSelf_item_$i"."_maxAggressives"} || $config{"useSelf_item_$i"."_maxAggressives"} >= ai_getAggressives()) 
				&& timeOut($config{"useSelf_item_$i"."_timeout"}, $ai_v{"useSelf_item_$i"."_time"}) 
				&& (!$config{"useSelf_item_$i"."_inLockOnly"} || ($config{"useSelf_item_$i"."_inLockOnly"} && $field{'name'} eq $config{'lockMap'}))) { 
				undef $ai_v{'temp'}{'invIndex'};
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
				if ($ai_v{'temp'}{'invIndex'} ne "") {
					sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
					$ai_v{"useSelf_item_$i"."_time"} = time;
					$timeout{'ai_item_use_auto'}{'time'} = time;
					print qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
					last;
				}
			}
#mod Stop
			$i++;
		}
	}

#mod Start
#Solos Auto-Equip
	##### AUTO-EQUIP #####

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || 
		 $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || 
		 $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take" || 
		 $ai_seq[0] eq "attack")&& timeOut(\%{$timeout{'ai_item_equip_auto'}}) 
		){
		$i = 0;
		while (1) {
			last if (!$config{"equipAuto_item_$i"});
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_item_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_item_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_item_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_item_$i"."_sp_lower"}
				&& $config{"equipAuto_item_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"equipAuto_item_$i"."_maxAggressives"} || $config{"equipAuto_item_$i"."_maxAggressives"} >= ai_getAggressives())
				&& (!$config{"equipAuto_item_$i"."_monsters"} || existsInList($config{"equipAuto_item_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
				&& (percent_weight(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_item_$i"."_weight"} || !$config{"equipAuto_item_$i"."_weight"})
				){ 
				undef $ai_v{'temp'}{'invIndex'};
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc_not_equip(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"equipAuto_item_$i"});
				if ($ai_v{'temp'}{'invIndex'} ne "") {
					sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'type_equip'});
					$timeout{'ai_item_equip_auto'}{'time'} = time;
					print qq~Auto-equip: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
					last;
				}
			}elsif ($config{"equipAuto_item_$i"."_def"}){
				undef $ai_v{'temp'}{'invIndex'};
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc_not_equip(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"equipAuto_item_$i"."_def"});
				if ($ai_v{'temp'}{'invIndex'} ne "") {
					sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'type_equip'});
					$timeout{'ai_item_equip_auto'}{'time'} = time;
					print qq~Auto-equip: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
				}
			}
			$i++;
		}
	}
#mod End

	##### AUTO-SKILL USE #####


	if ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" 
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack") {
		$i = 0;
		undef $ai_v{'useSelf_skill'};
		undef $ai_v{'useSelf_skill_lvl'};
		while (1) {
			last if (!$config{"useSelf_skill_$i"});
#mod Start
# Fix Auto useself skill
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_sp_lower"}
				&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{$config{"useSelf_skill_$i"."_lvl"}}
				&& timeOut($config{"useSelf_skill_$i"."_timeout"}, $ai_v{"useSelf_skill_$i"."_time"})
				&& !($config{"useSelf_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
				&& $config{"useSelf_skill_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"useSelf_skill_$i"."_maxAggressives"} || $config{"useSelf_skill_$i"."_maxAggressives"} >= ai_getAggressives())
				&& (!$config{"useSelf_skill_$i"."_inLockOnly"} || ($config{"useSelf_skill_$i"."_inLockOnly"} && $field{'name'} eq $config{'lockMap'}))
				&& (!$config{"useSelf_skill_$i"."_monsters"} || existsInList($config{"useSelf_skill_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
				) {
				$ai_v{"useSelf_skill_$i"."_time"} = time;
				$ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
				$ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
				$ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
				$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
				last;
			}
#mod Stop
			$i++;
		}
		if ($config{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
			undef $ai_v{'useSelf_skill_smartHeal_lvl'};
			$ai_v{'useSelf_skill_smartHeal_hp_dif'} = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
			for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'lv'}; $i++) {
				$ai_v{'useSelf_skill_smartHeal_lvl'} = $i;
				$ai_v{'useSelf_skill_smartHeal_sp'} = 10 + ($i * 3);
				$ai_v{'useSelf_skill_smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
						* (4 + $i * 8);
				if ($chars[$config{'char'}]{'sp'} < $ai_v{'useSelf_skill_smartHeal_sp'}) {
					$ai_v{'useSelf_skill_smartHeal_lvl'}--;
					last;
				}
				last if ($ai_v{'useSelf_skill_smartHeal_amount'} >= $ai_v{'useSelf_skill_smartHeal_hp_dif'});
			}
			$ai_v{'useSelf_skill_lvl'} = $ai_v{'useSelf_skill_smartHeal_lvl'};
		}
		if ($ai_v{'useSelf_skill_lvl'} > 0) {
			print qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (lvl $ai_v{'useSelf_skill_lvl'})\n~ if $config{'debug'};
			if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useSelf_skill'})})) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}
	}



	##### SKILL USE #####


	if ($ai_seq[0] eq "skill_use" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_minCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_maxCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "skill_use") {
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'skill_used'}) {
			$ai_seq_args[0]{'skill_used'} = 1;
			$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
			if ($ai_seq_args[0]{'skill_use_target_x'} ne "") {
				sendSkillUseLoc(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
			} else {
				sendSkillUse(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
			}
			$ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'};

		} elsif (($ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'}
			|| (timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}}) && (!$chars[$config{'char'}]{'time_cast'} || !$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}))
			|| ($ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}})))
			&& timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	
	##### FOLLOW #####


	if ($ai_seq[0] eq "" && $config{'follow'}) {
		ai_follow($config{'followTarget'});
	}
	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'suspended'}) {
		if ($ai_seq_args[0]{'ai_follow_lost'}) {
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		}
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'ai_follow_lost'}) {
		if (!$ai_seq_args[0]{'following'}) {
			foreach (keys %players) {
				if ($players{$_}{'name'} eq $ai_seq_args[0]{'name'} && !$players{$_}{'dead'}) {
					$ai_seq_args[0]{'ID'} = $_;
					$ai_seq_args[0]{'following'} = 1;
					last;
				}
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'pos_to'}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
			if ($ai_v{'temp'}{'dist'} > $config{'followDistanceMax'}) {
				ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'});
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'sitting'} == 1 && $chars[$config{'char'}]{'sitting'} == 0) {
			sit();
		}
	}

	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && ($players{$ai_seq_args[0]{'ID'}}{'dead'} || $players_old{$ai_seq_args[0]{'ID'}}{'dead'})) {
		print "Master died.  I'll wait here.\n";
		undef $ai_seq_args[0]{'following'};
	} elsif ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && !%{$players{$ai_seq_args[0]{'ID'}}}) {
		print "I lost my master\n";
		undef $ai_seq_args[0]{'following'};
		if ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			print "My master disconnected\n";
			
		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disappeared'}) {
			print "Trying to find lost master\n";
			undef $ai_seq_args[0]{'ai_follow_lost_char_last_pos'};
			undef $ai_seq_args[0]{'follow_lost_portal_tried'};
			$ai_seq_args[0]{'ai_follow_lost'} = 1;
			$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
			getVector(\%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, \%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

			#check if player went through portal
			$ai_v{'temp'}{'first'} = 1;
			undef $ai_v{'temp'}{'foundID'};
			undef $ai_v{'temp'}{'smallDist'};
			foreach (@portalsID) {
				$ai_v{'temp'}{'dist'} = distance(\%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$portals{$_}{'pos'}});
				if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
					$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
			$ai_seq_args[0]{'follow_lost_portalID'} = $ai_v{'temp'}{'foundID'};
		} else {
			print "Don't know what happened to Master\n";
		}
	}




	##### FOLLOW-LOST #####


	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'ai_follow_lost'}) {
		if ($ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
			$ai_seq_args[0]{'lost_stuck'}++;
		} else {
			undef $ai_seq_args[0]{'lost_stuck'};
		}
		%{$ai_seq_args[0]{'ai_follow_lost_char_last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

		if (timeOut(\%{$ai_seq_args[0]{'ai_follow_lost_end'}})) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "Couldn't find master, giving up\n";

		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "My master disconnected\n";

		} elsif (%{$players{$ai_seq_args[0]{'ID'}}}) {
			$ai_seq_args[0]{'following'} = 1;
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "Found my master!\n";

		} elsif ($ai_seq_args[0]{'lost_stuck'}) {
			if ($ai_seq_args[0]{'follow_lost_portalID'} eq "") {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'} / ($ai_seq_args[0]{'lost_stuck'} + 1));
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		} else {
			if ($ai_seq_args[0]{'follow_lost_portalID'} ne "") {
				if (%{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}} && !$ai_seq_args[0]{'follow_lost_portal_tried'}) {
					$ai_seq_args[0]{'follow_lost_portal_tried'} = 1;
					%{$ai_v{'temp'}{'pos'}} = %{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}{'pos'}};
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);
				}
			} else {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'});
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		}
	}

	##### AUTO-SIT/SIT/STAND #####


	if ($config{'sitAuto_idle'} && ($ai_seq[0] ne "" && $ai_seq[0] ne "follow")) {
		$timeout{'ai_sit_idle'}{'time'} = time;
	}
	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow") && $config{'sitAuto_idle'} && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit_idle'}})) {
		sit();
	}
	if ($ai_seq[0] eq "sitting" && ($chars[$config{'char'}]{'sitting'} || $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} < 3)) {
		shift @ai_seq;
		shift @ai_seq_args;
		$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
	} elsif ($ai_seq[0] eq "sitting" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}}) && timeOut(\%{$timeout{'ai_sit_wait'}})) {
		sendSit(\$remote_socket);
		$timeout{'ai_sit'}{'time'} = time;
	}
#mod Start
# Make Chat after sit
	if ($chars[$config{'char'}]{'sitting'} && !$timeout{'ai_makechatAuto'}{'time'} && $config{'makeChatwhenSit'}) {
		$timeout{'ai_makechatAuto'}{'time'} = time;
	}elsif (!$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_makechatAuto'}}) && $config{'makeChatwhenSit'}) {
		undef $timeout{'ai_makechatAuto'}{'time'};
	}elsif ($chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_makechatAuto'}}) && $config{'makeChatwhenSit'} && $currentChatRoom eq "") {
		sendLook(\$remote_socket,int(rand(8)),0);
		$title = getResMsg("/Chatroom");
		if ($title ne "") {
			$arg[0] = "20"; 
			$arg[1] = "0"; 
			$arg[2] = vocalString(4); 
			sendChatRoomCreate(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
			$createdChatRoom{'title'} = $title;
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = $arg[0];
			$createdChatRoom{'public'} = $arg[1];
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
		}
	}elsif ($ai_seq[0] eq "standing" && $currentChatRoom ne "" ){
		sendChatRoomLeave(\$remote_socket);
		undef $timeout{'ai_makechatAuto'}{'time'};
	}
#mod Stop
	if ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && !$timeout{'ai_stand_wait'}{'time'}) {
		$timeout{'ai_stand_wait'}{'time'} = time;
	} elsif ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_stand_wait'}})) {
		shift @ai_seq;
		shift @ai_seq_args;
		undef $timeout{'ai_stand_wait'}{'time'};
		$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
	} elsif ($ai_seq[0] eq "standing" && $chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}})) {
		sendStand(\$remote_socket);
		$timeout{'ai_sit'}{'time'} = time;
	}

	if ($ai_v{'sitAuto_forceStop'} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_lower'}) {
		$ai_v{'sitAuto_forceStop'} = 0;
	}
#mod Start
# storage or sell before sit
	if (!$ai_v{'sitAuto_forceStop'} && ($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && binFind(\@ai_seq, "attack") eq "" && !ai_getAggressives()
		&& (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'})
		&& binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "") {
		unshift @ai_seq, "sitAuto";
		unshift @ai_seq_args, {};
		print "Auto-sitting\n" if $config{'debug'};
	}
#mod Stop
	if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3 && !ai_getAggressives()) {
		sit();
	}
	if ($ai_seq[0] eq "sitAuto" && ($ai_v{'sitAuto_forceStop'}
		|| (percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_upper'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_upper'}))) {
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$config{'sitAuto_idle'} && $chars[$config{'char'}]{'sitting'}) {
			stand();
		}
	}


	##### AUTO-ATTACK #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow" 
		|| $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take")
		&& !($config{'itemsTakeAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_take"))
		&& !($config{'itemsGatherAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"))
		&& timeOut(\%{$timeout{'ai_attack_auto'}})) {
		undef @{$ai_v{'ai_attack_agMonsters'}};
		undef @{$ai_v{'ai_attack_cleanMonsters'}};
		undef @{$ai_v{'ai_attack_partyMonsters'}};
		undef $ai_v{'temp'}{'foundID'};
		if ($config{'tankMode'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@playersID) {	
				next if ($_ eq "");
				if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
		}
		if (!$config{'tankMode'} || ($config{'tankMode'} && $ai_v{'temp'}{'found'})) {
			$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
			if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
				$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
				$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
			} else {
				undef $ai_v{'temp'}{'ai_follow_following'};
			}
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives() if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'}));
			foreach (@monstersID) {
				next if ($_ eq "");
#mod Start
# Detect Frozen & Trap Monster
				if ($monsters{$ID}{'frozen'}==0) {
					if ((($config{'attackAuto_party'}
						&& $ai_seq[0] ne "take" && $ai_seq[0] ne "items_take"
						&& ($monsters{$_}{'dmgToParty'} > 0 || $monsters{$_}{'dmgFromParty'} > 0))
						|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} 
						&& ($monsters{$_}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$_}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0)))
						&& !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})
						&& $monsters{$_}{'attack_failed'} == 0 && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
						push @{$ai_v{'ai_attack_partyMonsters'}}, $_;
					} elsif ($config{'attackAuto'} >= 2
						&& $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
						&& !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})) && $monsters{$_}{'attack_failed'} == 0
						&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
						&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
#Avoid KSing
						undef $m_plDist_small;
						my $judgeFirst = 1;
						my $m_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						for ($i = 0; $i < @playersID; $i++) {
							next if ($playersID[$i] eq "");
							$m_plDist = distance(\%{$players{$playersID[$i]}{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
							if ($judgeFirst || $m_plDist < $m_plDist_small) {
								$m_plDist_small = $m_plDist;
								$judgeFirst = 0;
							}
						}
						if(!$m_plDist_small || $m_plDist_small >= $config{'NotAttackDistance'} || $m_cDist <= $m_plDist_small) {
							if ($ai_v{'ai_attack_cleanMonsters'} 
								&& ( $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$ai_v{'ai_attack_cleanMonsters'}[0]}{'name'})}{'attack_auto'}
										|| $m_cDist < distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_v{'ai_attack_cleanMonsters'}[0]}{'pos_to'}})
									  )
								) {
								unshift @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
							}else{
								push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
							}
						}
						#push @{$ai_v{'ai_attack_cleanMonsters'}}, $_ if !$m_plDist_small || $m_plDist_small >= $config{'NotAttackDistance'} || $m_cDist <= $m_plDist_small;
					}
				}
#mod Stop
			}
			undef $ai_v{'temp'}{'distSmall'};
			undef $ai_v{'temp'}{'foundID'};
			$ai_v{'temp'}{'first'} = 1;
			foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
				if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
			if (!$ai_v{'temp'}{'foundID'}) {
				undef $ai_v{'temp'}{'distSmall'};
				undef $ai_v{'temp'}{'foundID'};
				$ai_v{'temp'}{'first'} = 1;
				foreach (@{$ai_v{'ai_attack_partyMonsters'}}) {
					$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
						$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
			}
			if (!$ai_v{'temp'}{'foundID'}) {
				undef $ai_v{'temp'}{'distSmall'};
				undef $ai_v{'temp'}{'foundID'};
				$ai_v{'temp'}{'first'} = 1;
				foreach (@{$ai_v{'ai_attack_cleanMonsters'}}) {
					$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
						$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
			}
		}	
		if ($ai_v{'temp'}{'foundID'}) {
			ai_setSuspend(0);
			attack($ai_v{'temp'}{'foundID'});
		} else {
			$timeout{'ai_attack_auto'}{'time'} = time;
		}
	}




	##### ATTACK #####


	if ($ai_seq[0] eq "attack" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_attack_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "attack" && timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}})) {
		$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
		print "Can't reach or damage target, dropping target\n";
	} elsif ($ai_seq[0] eq "attack" && !%{$monsters{$ai_seq_args[0]{'ID'}}}) {
		$timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
		$ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
		shift @ai_seq;
		shift @ai_seq_args;
		if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
			print "Target died\n";
#Mod Start
#Add Data to Monster Report
			open (TMPMON, ">> logs\/$config{'username'}_Tmpmr.txt"); 
			print TMPMON "$monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'}\n"; 
			close (TMPMON);
#Mod Stop
			if ($config{'itemsTakeAuto'} && $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
				ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
			} else {
				ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			}
		} else {
			print "Target lost\n";
		}
	} elsif ($ai_seq[0] eq "attack") {
		$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
		if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
			$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
			$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
		} else {
			undef $ai_v{'temp'}{'ai_follow_following'};
		}
		$ai_v{'ai_attack_monsterDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}});
		$ai_v{'ai_attack_cleanMonster'} = (!($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0 && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0 || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}}))
				|| ($config{'attackAuto_party'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromParty'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0))
				|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0))
				|| ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0));
		if ($ai_seq_args[0]{'dmgToYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'}
			|| $ai_seq_args[0]{'missedYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}
			|| $ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
		}
		$ai_seq_args[0]{'dmgToYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'};
		$ai_seq_args[0]{'missedYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'};
		$ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'};
		$ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'};
		if (!%{$ai_seq_args[0]{'attackMethod'}}) {
			if ($config{'attackUseWeapon'}) {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{'attackDistance'};
				$ai_seq_args[0]{'attackMethod'}{'type'} = "weapon";
			} else {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = 30;
				undef $ai_seq_args[0]{'attackMethod'}{'type'};
			}
			$i = 0;
			while ($config{"attackSkillSlot_$i"} ne "") {
				$i++ if(!%{$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}});
				if (percent_hp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_hp_upper"}
					&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_sp_upper"}
					&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{$config{"attackSkillSlot_$i"."_lvl"}}
					&& !($config{"attackSkillSlot_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
					&& (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
					&& $config{"attackSkillSlot_$i"."_minAggressives"} <= ai_getAggressives()
					&& (!$config{"attackSkillSlot_$i"."_maxAggressives"} || $config{"attackSkillSlot_$i"."_maxAggressives"} >= ai_getAggressives())
					&& (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))) {
					$ai_seq_args[0]{'attackSkillSlot_uses'}{$i}++;
					$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{"attackSkillSlot_$i"."_dist"};
					$ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
					$ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;
					# Looping skills support 
					if ($config{"attackSkillSlot_$i"."_loopSlot"} ne "") { 
						undef $ai_v{qq~attackSkillSlot_$config{"attackSkillSlot_$i"."_loopSlot"}~."_time"}; 
						undef $ai_seq_args[0]{'attackSkillSlot_uses'}{$config{"attackSkillSlot_$i"."_loopSlot"}}; 
					}
					last;
				}
				$i++;
			}
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_v{'ai_attack_cleanMonster'}) {
			shift @ai_seq;
			shift @ai_seq_args;
			print "Dropping target - no kill steal\n";
		} elsif ($ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
			if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
				&& $ai_seq_args[0]{'attackMethod_last'}{'distance'} == $ai_seq_args[0]{'attackMethod'}{'distance'}
				&& $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
				$ai_seq_args[0]{'distanceDivide'}++;
			} else {
				$ai_seq_args[0]{'distanceDivide'} = 1;
			}
			if (int($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) == 0
				|| ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'})
				|| ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'})) {
				$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
				shift @ai_seq;
				shift @ai_seq_args;
				print "Dropping target - couldn't reach target\n";
			} else {
				getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) + 1);

				%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
				%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};
			
				ai_setSuspend(0);
				if (@{$field{'field'}} > 1) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
				} else {
					move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
				}
			}
		} elsif ((($config{'tankMode'} && $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0)
			|| !$config{'tankMode'})) {

			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "weapon" && timeOut(\%{$timeout{'ai_attack'}})) {
				if ($config{'tankMode'}) {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 0);
				} else {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 7);
				}
				$timeout{'ai_attack'}{'time'} = time;
				undef %{$ai_seq_args[0]{'attackMethod'}};
			} elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "skill") {
				$ai_v{'ai_attack_method_skillSlot'} = $ai_seq_args[0]{'attackMethod'}{'skillSlot'};
				$ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
				undef %{$ai_seq_args[0]{'attackMethod'}};
				ai_setSuspend(0);
				if (!ai_getSkillUseType($skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})})) {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $ai_v{'ai_attack_ID'});
				} else {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'});
				}
				print qq~Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"})\n~ if $config{'debug'};
			}
			
		} elsif ($config{'tankMode'}) {
			if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
		}
	}

	
	##### ROUTE #####

	ROUTE: {

	if ($ai_seq[0] eq "route" && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1 && $ai_seq_args[0]{'solutionReady'}) {
		print "Route success\n" if $config{'debug'};
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "route" && $ai_seq_args[0]{'failed'}) {
		print "Route failed\n" if $config{'debug'};
		shift @ai_seq;
		shift @ai_seq_args;
#mod Start
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
#mod Stop
	} elsif ($ai_seq[0] eq "route" && timeOut(\%{$timeout{'ai_route_npcTalk'}})) {
		last ROUTE if (!$field{'name'});
		if ($ai_seq_args[0]{'waitingForMapSolution'}) {
			undef $ai_seq_args[0]{'waitingForMapSolution'};
			if (!@{$ai_seq_args[0]{'mapSolution'}}) {
				print "NPC talk - route failed\n";
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'mapIndex'} = -1;
		}
		if ($ai_seq_args[0]{'waitingForSolution'}) {
			undef $ai_seq_args[0]{'waitingForSolution'};
			if ($ai_seq_args[0]{'distFromGoal'} && $field{'name'} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} 
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				for ($i = 0; $i < $ai_seq_args[0]{'distFromGoal'}; $i++) {
					pop @{$ai_seq_args[0]{'solution'}};
				}
				if (@{$ai_seq_args[0]{'solution'}}) {
					$ai_seq_args[0]{'dest_x_original'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'dest_y_original'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'x'};
					$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'y'};
				}
			}
			$ai_seq_args[0]{'returnHash'}{'solutionLength'} = @{$ai_seq_args[0]{'solution'}};
			$ai_seq_args[0]{'returnHash'}{'solutionTime'} = time - $ai_seq_args[0]{'time_getRoute'};
			if ($ai_seq_args[0]{'maxRouteDistance'} && @{$ai_seq_args[0]{'solution'}} > $ai_seq_args[0]{'maxRouteDistance'}) {
				print "Solution length - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			if (!@{$ai_seq_args[0]{'solution'}} && !@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} && $ai_seq_args[0]{'checkInnerPortals'} && !$ai_seq_args[0]{'checkInnerPortals_done'}) {
				$ai_seq_args[0]{'checkInnerPortals_done'} = 1;
				print "Route Logic - check inner portals done\n" if $config{'debug'};
				undef $ai_seq_args[0]{'solutionReady'};
				$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'waitingForMapSolution'} = 1;
				ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%field, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
				last ROUTE;
			} elsif (!@{$ai_seq_args[0]{'solution'}}) {
				print "No solution - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
		}
		if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapChanged'} && $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'}) {
			print "Route logic - map changed\n" if $config{'debug'};	
			undef $ai_seq_args[0]{'mapChanged'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
		}
		if (!@{$ai_seq_args[0]{'solution'}}) {
			if ($ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				$ai_seq_args[0]{'temp'}{'dest'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'dest'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'solutionReady'} = 1;
				undef @{$ai_seq_args[0]{'mapSolution'}};
				undef $ai_seq_args[0]{'mapIndex'};
				print "Route logic - solution ready\n" if $config{'debug'};
			} else {
				if (!(@{$ai_seq_args[0]{'mapSolution'}})) {
					if (!%{$ai_seq_args[0]{'dest_field'}}) {
						getField("fields/$ai_seq_args[0]{'dest_map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
					}
					$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'waitingForMapSolution'} = 1;
					print "Route logic - waiting for map solution\n" if $config{'debug'};
					ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'dest_field'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
					last ROUTE;
				}
				if ($field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
					$ai_seq_args[0]{'mapIndex'}++;
					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				} else {
					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				}
			}
			if ($ai_seq_args[0]{'temp'}{'dest'}{'x'} eq "") {
				print "No destination - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'waitingForSolution'} = 1;
			$ai_seq_args[0]{'time_getRoute'} = time;
			print "Route logic - waiting for solution\n" if $config{'debug'};
			ai_route_getRoute(\@{$ai_seq_args[0]{'solution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'temp'}{'dest'}}, $ai_seq_args[0]{'maxRouteTime'});
			last ROUTE;
		}
		if (@{$ai_seq_args[0]{'mapSolution'}} && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1
			&& %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}) {
			if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {
				if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
					sendTalk(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) { 
					sendTalkContinue(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'})); 
					$ai_seq_args[0]{'npc'}{'step'}++; 
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) { 
					sendTalkCancel(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'})); 
					$ai_seq_args[0]{'npc'}{'step'}++;
				} else {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						$ai_v{'temp'}{'arg'}++;
						sendTalkResponse(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
					}
					$ai_seq_args[0]{'npc'}{'step'}++;
				}
				$timeout{'ai_route_npcTalk'}{'time'} = time;
				last ROUTE;
			}
		}
		if ($ai_seq_args[0]{'mapChanged'}) {
			print "Map changed - route failed\n" if $config{'debug'};
			$ai_seq_args[0]{'failed'} = 1;
			last ROUTE;

		} elsif (%{$ai_seq_args[0]{'last_pos'}}
			&& $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
			&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}
			&& $ai_seq_args[0]{'last_pos'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
			&& $ai_seq_args[0]{'last_pos'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {

			if ($ai_seq_args[0]{'dest_x_original'} ne "") {
				$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'dest_x_original'};
				$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'dest_y_original'};
			}
			print "Route logic - last pos\n" if $config{'debug'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
	
		} else {
			if ($ai_seq_args[0]{'divideIndex'} && $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
				&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {

				#we're stuck!
				print "Route logic - stuck\n" if $config{'debug'};
				$ai_v{'temp'}{'index_old'} = $ai_seq_args[0]{'index'};
				$ai_seq_args[0]{'index'} -= int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = 0 if ($ai_seq_args[0]{'index'} < 0);
				$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
				undef $ai_v{'temp'}{'done'};
				do {
					$ai_seq_args[0]{'divideIndex'}++;
					$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
					$ai_v{'temp'}{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
					$ai_v{'temp'}{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_v{'temp'}{'index'} >= @{$ai_seq_args[0]{'solution'}});
					$ai_v{'temp'}{'done'} = 1 if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0);
				} while ($ai_v{'temp'}{'index'} >= $ai_v{'temp'}{'index_old'} && !$ai_v{'temp'}{'done'});
			} else {
				$ai_seq_args[0]{'divideIndex'} = 1;
				print "Route logic - divide index = 1\n" if $config{'debug'};
#mod Start
				$pos_x = int($chars[$config{'char'}]{'pos_to'}{'x'}) if ($chars[$config{'char'}]{'pos_to'}{'x'} ne "");
				$pos_y = int($chars[$config{'char'}]{'pos_to'}{'y'}) if ($chars[$config{'char'}]{'pos_to'}{'y'} ne "");
				#if kore is stuck
				if (($old_pos_x == $pos_x) && ($old_pos_y == $pos_y)) {
					$route_stuck++;
				} else {
					$route_stuck = 0;
					$old_pos_x = $pos_x;
					$old_pos_y = $pos_y;
				}
				if ($route_stuck >= 50) {
					ClearRouteAI("Route failed, clearing route AI to unstuck ...\n");
					last ROUTE;
				}
				if ($route_stuck >= 80) {
					$route_stuck = 0;
					Unstuck("Route failed, trying to unstuck ...\n");
					last ROUTE;
				}	
				if ($totalStuckCount >= 10) {
					RespawnUnstuck();
					last ROUTE;
				}		
#mod Stop
			}

				
			if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0) {
				print "Route step - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

			%{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};
			
			do {
				$ai_seq_args[0]{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_seq_args[0]{'index'} >= @{$ai_seq_args[0]{'solution'}});
			} while ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}
				&& $ai_seq_args[0]{'index'} != @{$ai_seq_args[0]{'solution'}} - 1);
			
			if ($ai_seq_args[0]{'avoidPortals'}) {
				$ai_v{'temp'}{'first'} = 1;
				undef $ai_v{'temp'}{'foundID'};
				undef $ai_v{'temp'}{'smallDist'};
				foreach (@portalsID) {
					$ai_v{'temp'}{'dist'} = distance(\%{$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]}, \%{$portals{$_}{'pos'}});
					if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
						print "Route logic - portal found\n" if $config{'debug'};
					}
				}
				if ($ai_v{'temp'}{'foundID'}) {
					print "Cannot found portal ID - route failed\n" if $config{'debug'};
					$ai_seq_args[0]{'failed'} = 1;
					last ROUTE;
				}
			}
			if ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
				|| $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
				if($config{'modifiedWalkType'}){ 
					modifiedWalk($config{'modifiedWalkType'});
				}
				move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});
			}
		}
	}
	
	} #END OF ROUTE BLOCK
	

	##### ROUTE_GETROUTE #####

	if ($ai_seq[0] eq "route_getRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
		if (!$ai_seq_args[0]{'init'}) {
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			$ai_seq_args[0]{'timeout'} = $timeout{'ai_route_calcRoute'}{'timeout'}*1000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		$timeout{'ai_route_calcRoute_cont'}{'time'} = time;
		ai_setSuspend(0);
	}

	##### ROUTE_GETMAPROUTE #####

	ROUTE_GETMAPROUTE: {

	if ($ai_seq[0] eq "route_getMapRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getMapRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getMapRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
		if (!%{$ai_seq_args[0]{'start'}}) {
			%{$ai_seq_args[0]{'start'}{'dest'}{'pos'}} = %{$ai_seq_args[0]{'r_start_pos'}};
			$ai_seq_args[0]{'start'}{'dest'}{'map'} = $ai_seq_args[0]{'r_start_field'}{'name'};
			$ai_seq_args[0]{'start'}{'dest'}{'field'} = $ai_seq_args[0]{'r_start_field'};
			%{$ai_seq_args[0]{'dest'}{'source'}{'pos'}} = %{$ai_seq_args[0]{'r_dest_pos'}};
			$ai_seq_args[0]{'dest'}{'source'}{'map'} = $ai_seq_args[0]{'r_dest_field'}{'name'};
			$ai_seq_args[0]{'dest'}{'source'}{'field'} = $ai_seq_args[0]{'r_dest_field'};
			push @{$ai_seq_args[0]{'openList'}}, \%{$ai_seq_args[0]{'start'}};
		}
		$timeout{'ai_route_calcRoute'}{'time'} = time;
		while (!$ai_seq_args[0]{'done'} && !timeOut(\%{$timeout{'ai_route_calcRoute'}})) {
			ai_mapRoute_searchStep(\%{$ai_seq_args[0]});
			last ROUTE_GETMAPROUTE if ($ai_seq[0] ne "route_getMapRoute");
		}

		if ($ai_seq_args[0]{'done'}) {
			@{$ai_seq_args[0]{'returnArray'}} = @{$ai_seq_args[0]{'solutionList'}};
		}
		$timeout{'ai_route_calcRoute_cont'}{'time'} = time;
		ai_setSuspend(0);
	}

	} #End of block ROUTE_GETMAPROUTE


	##### ITEMS TAKE #####


	if ($ai_seq[0] eq "items_take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_take_start'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_items_take_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
#mod Start
# on route storageAuto occur attack aggressive monster -> take it item !!
	if ($ai_seq[0] eq "items_take"
		&& (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'} || percent_weight(\%{$chars[$config{'char'}]}) >=89)
		&& !$config{'itemsGreedyMode'}
		){
#mod Stop
		shift @ai_seq;
		shift @ai_seq_args;
		ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
	}
	if ($config{'itemsTakeAuto'} && $ai_seq[0] eq "items_take" && timeOut(\%{$ai_seq_args[0]{'ai_items_take_start'}})) {
		undef $ai_v{'temp'}{'foundID'};
		foreach (@itemsID) {
			next if ($_ eq "" || $itemsPickup{lc($items{$_}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$_}{'name'})}));
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos'}});
			$ai_v{'temp'}{'dist_to'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos_to'}});
			if (($ai_v{'temp'}{'dist'} <= 4 || $ai_v{'temp'}{'dist_to'} <= 4) && $items{$_}{'take_failed'} == 0) {
				$ai_v{'temp'}{'foundID'} = $_;
				last;
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_seq_args[0]{'ai_items_take_end'}{'time'} = time;
			$ai_seq_args[0]{'started'} = 1;
			take($ai_v{'temp'}{'foundID'});
		} elsif ($ai_seq_args[0]{'started'} || timeOut(\%{$ai_seq_args[0]{'ai_items_take_end'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
			ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
		}
	}



	##### ITEMS AUTO-GATHER #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && $config{'itemsGatherAuto'} && !(percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) && timeOut(\%{$timeout{'ai_items_gather_auto'}})) {
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		foreach (@playersID) {
			next if ($_ eq "");
			if (!%{$chars[$config{'char'}]{'party'}} || !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach $item (@itemsID) {
			next if ($item eq "" || time - $items{$item}{'appear_time'} < $timeout{'ai_items_gather_start'}{'timeout'}
				|| $items{$item}{'take_failed'} >= 1
				|| $itemsPickup{lc($items{$item}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$item}{'name'})}));
			undef $ai_v{'temp'}{'dist'};
			undef $ai_v{'temp'}{'found'};
			foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$items{$item}{'pos'}}, \%{$players{$_}{'pos_to'}});
				if ($ai_v{'temp'}{'dist'} < 9) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if ($ai_v{'temp'}{'found'} == 0) {
				gather($item);
				last;
			}
		}
		$timeout{'ai_items_gather_auto'}{'time'} = time;
	}



	##### ITEMS GATHER #####


	if ($ai_seq[0] eq "items_gather" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_gather_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "items_gather" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		print "Failed to gather $items_old{$ai_seq_args[0]{'ID'}}{'name'} ($items_old{$ai_seq_args[0]{'ID'}}{'binID'}) : Lost target\n";
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "items_gather") {
		undef $ai_v{'temp'}{'dist'};
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		undef $ai_v{'temp'}{'found'};
		foreach (@playersID) {
			next if ($_ eq "");
			if (%{$chars[$config{'char'}]{'party'}} && !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$players{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} < 9) {
				$ai_v{'temp'}{'found'}++;
			}
		}
		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if (timeOut(\%{$ai_seq_args[0]{'ai_items_gather_giveup'}})) {
			print "Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : Timeout\n";
			$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif ($ai_v{'temp'}{'found'} == 0 && $ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif ($ai_v{'temp'}{'found'} == 0) {
			$ai_v{'ai_items_gather_ID'} = $ai_seq_args[0]{'ID'};
			shift @ai_seq;
			shift @ai_seq_args;
			take($ai_v{'ai_items_gather_ID'});
		} elsif ($ai_v{'temp'}{'found'} > 0) {
			print "Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : No looting!\n";
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	##### TAKE #####


	if ($ai_seq[0] eq "take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_take_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "take" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take" && timeOut(\%{$ai_seq_args[0]{'ai_take_giveup'}})) {
		print "Failed to take $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'})\n";
		$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take") {

		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if ($chars[$config{'char'}]{'sitting'}) {
			stand();
		} elsif ($ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif (timeOut(\%{$timeout{'ai_take'}})) {
			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'});
			$timeout{'ai_take'}{'time'} = time;
		}
	}

	
	##### MOVE #####


	if ($ai_seq[0] eq "move" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_move_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "move") {
		if (!$ai_seq_args[0]{'ai_moved'} && $ai_seq_args[0]{'ai_moved_tried'} && $ai_seq_args[0]{'ai_move_time_last'} != $chars[$config{'char'}]{'time_move'}) {
			$ai_seq_args[0]{'ai_moved'} = 1;
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'ai_moved'} && timeOut(\%{$ai_seq_args[0]{'ai_move_giveup'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$ai_seq_args[0]{'ai_moved_tried'}) {
			sendMove(\$remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
			$ai_seq_args[0]{'ai_move_giveup'}{'time'} = time;
			$ai_seq_args[0]{'ai_move_time_last'} = $chars[$config{'char'}]{'time_move'};
			$ai_seq_args[0]{'ai_moved_tried'} = 1;
		} elsif ($ai_seq_args[0]{'ai_moved'} && time - $chars[$config{'char'}]{'time_move'} >= $chars[$config{'char'}]{'time_move_calc'}) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	##### AUTO-TELEPORT #####

	($ai_v{'map_name_lu'}) = $map_name =~ /([\s\S]*)\./;
	$ai_v{'map_name_lu'} .= ".rsw";
	if ($config{'teleportAuto_onlyWhenSafe'} && binSize(\@playersID)) {
		undef $ai_v{'ai_teleport_safe'};
		if (!$cities_lut{$ai_v{'map_name_lu'}} && timeOut(\%{$timeout{'ai_teleport_safe_force'}})) {
			$ai_v{'ai_teleport_safe'} = 1;
		}
	} elsif (!$cities_lut{$ai_v{'map_name_lu'}}) {
		$ai_v{'ai_teleport_safe'} = 1;
		$timeout{'ai_teleport_safe_force'}{'time'} = time;
	} else {
		undef $ai_v{'ai_teleport_safe'};
	}

	if (timeOut(\%{$timeout{'ai_teleport_away'}}) && $ai_v{'ai_teleport_safe'}) {
		foreach (@monstersID) {
			if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'}) {
				useTeleport(1);
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
#mod Start
#avoiding players
		foreach (@playersID) {
			#Exclusive Avoid
			if ($config{'Exclusive_Avoid'}==1 && !$cities_lut{$field{'name'}.'.rsw'} && ($field{'name'} eq $config{'lockMap'} || $config{'lockMap'} eq "")
				&& ($players{$_}{'jobID'}==4 || $players{$_}{'jobID'}==8)) {
				print "Force Exclusive Avoid : $players{$_}{'name'} ($players{$_}{'nameID'}) [$jobs_lut{$players{$_}{'jobID'}}]\n";
				chatLog("D", "**Force Exclusive Avoid : $players{$_}{'name'} ($players{$_}{'nameID'}) [$jobs_lut{$players{$_}{'jobID'}}]"."\n");
				useTeleport(1);
				last;
			}elsif ($config{'Exclusive_Avoid'}==2 && !$cities_lut{$field{'name'}.'.rsw'} && ($field{'name'} eq $config{'lockMap'} || $config{'lockMap'} eq "")){
				useTeleport(1);
				last;
			}
			if (($ppl_control{$players{$_}{'name'}}{'teleport_auto'} || (($players{$_}{'name'} =~/^GM/ || $players{$_}{'name'} =~/^��µ�Ǩ/ || $GameMasters{$_}) && $config{'AvoidGM'}))
				 && !$cities_lut{$field{'name'}.'.rsw'} ) {
				if ($ppl_control{$players{$_}{'name'}}{'teleport_auto'}){
					print "Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}), use teleport lv $ppl_control{$players{$_}{'name'}}{'teleport_auto'}\n";
					chatLog("D","**Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}), use teleport lv $ppl_control{$players{$_}{'name'}}{'teleport_auto'}\n");
					useTeleport($ppl_control{$players{$_}{'name'}}{'teleport_auto'});
				}elsif ($config{'AvoidGM'}<3) {
					print "Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}), use teleport lv $config{'AvoidGM'}\n";
					chatLog("D","**Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}), use teleport lv $config{'AvoidGM'}\n");
					useTeleport($config{'AvoidGM'});
				}
				last if (%{$ppl_control{$players{$_}{'name'}}} && $ppl_control{$players{$_}{'name'}}{'disconnect_auto'}==0);
			}
			if (($ppl_control{$players{$_}{'name'}}{'disconnect_auto'} || (($players{$_}{'name'} =~/^GM/ || $players{$_}{'name'} =~/^��µ�Ǩ/ || $GameMasters{$_}) && $config{'AvoidGM'}==3))
				&& !$cities_lut{$field{'name'}.'.rsw'}) {
				print "Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}), Disconnect...\n";
				chatLog("D","**Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}), Disconnect...\n");
				$timeout_ex{'master'}{'time'} = time;
				$timeout_ex{'master'}{'timeout'} = $config{'Avoid_Reconnect'};
				killConnection(\$remote_socket);
				last;
			}
		}
#mod Stop
		$timeout{'ai_teleport_away'}{'time'} = time;
	}

	if ((($config{'teleportAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_hp'} && ai_getAggressives())
		|| ($config{'teleportAuto_minAggressives'} && ai_getAggressives() >= $config{'teleportAuto_minAggressives'})
		)
		&& $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}})) {
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_hp'}{'time'} = time;
	}

#mod Start
	if ($config{'teleportAuto_search'} && timeOut(\%{$timeout{'ai_teleport_search'}}) && binFind(\@ai_seq, "attack") eq ""  && $ai_v{'ai_teleport_safe'} 
		&& binFind(\@ai_seq, "items_take") eq "" && binFind(\@ai_seq, "sitAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "" && ($field{'name'} eq $config{'lockMap'} || $config{'lockMap'} eq "")) {
#mod Stop
		undef $ai_v{'temp'}{'search'};
		foreach (keys %mon_control) {
			if ($mon_control{$_}{'teleport_search'}) {
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		if ($ai_v{'temp'}{'search'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@monstersID) {
				if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_search'} && !$monsters{$_}{'attack_failed'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
#mod Start
# Teleport Search
			if (!$ai_v{'temp'}{'found'}) {
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
			}
#mod Stop
		}
		$timeout{'ai_teleport_search'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && $ai_seq[0] ne "") {
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && timeOut(\%{$timeout{'ai_teleport_idle'}}) && $ai_v{'ai_teleport_safe'}) {
		useTeleport($config{'teleportAuto_idle'});
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}
#mod Start
# avoid portal in lockMap
	if ($config{'teleportAuto_portal'} && timeOut(\%{$timeout{'ai_teleport_portal'}}) && $ai_v{'ai_teleport_safe'}
	   &&($field{'name'} eq $config{'lockMap'} || $config{'lockMap'} eq "")) {
		if (binSize(\@portalsID)) {
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
		}
		$timeout{'ai_teleport_portal'}{'time'} = time;
	}
#mod Stop

#mod Start
# ChatAuto part 2 & Pet Check Status
	##### RESPONSE - AUTO #####
	if ($ai_seq[0] eq "chatauto" && timeOut(\%{$ppllog{'talktime'}})){
		if ($ppllog{'cmd'}{"$ppllog{'name'}"}{'ans'} =~ /^e \d+/) {
			($arg1) = $ppllog{'cmd'}{"$ppllog{'name'}"}{'ans'} =~ /[\s\S+] (\d+)/;
			sendEmotion(\$remote_socket, $arg1);
		}elsif ($ppllog{'type'} eq "pm") {
			sendMessage(\$remote_socket, "pm", $ppllog{'cmd'}{"$ppllog{'name'}"}{'ans'},$ppllog{'name'});
		}else {
			sendMessage(\$remote_socket, "c", $ppllog{'cmd'}{"$ppllog{'name'}"}{'ans'});
		}
		undef $ppllog{'talktime'}{'time'};
		shift @ai_seq;
		shift @ai_seq_args;
	}

	##### Q' pet ####
	if (%{$chars[$config{'char'}]{'pet'}}){
		if (!$timeout{'ai_petPlay'}{'time'} && $config{'petAutoPlay'}){
			$timeout{'ai_petPlay'}{'time'}=time;
		}elsif (timeOut(\%{$timeout{'ai_petPlay'}}) && $config{'petAutoPlay'}){
			sendPetCommand(\$remote_socket,2);
			$timeout{'ai_petPlay'}{'time'}=time;
			print "Auto Play pet\n";
		}
	}
	
	##### Auto-Speak #####
	if (!$timeout{'ai_AutoSpeak'}{'time'} && $config{'AutoSpeak'}) {
		$timeout{'ai_AutoSpeak'}{'time'} = time;
	}elsif (timeOut(\%{$timeout{'ai_AutoSpeak'}}) && $config{'AutoSpeak'}) {
		$arg = getResMsg("/AutoSpeak");
		if ($arg ne "") {
			if ($arg =~ /^e \d+/) {
				($arg1) = $arg =~ /[\s\S+] (\d+)/;
				sendEmotion(\$remote_socket, $arg1);
			}else {
				sendMessage(\$remote_socket, "c", $arg);
			}
		}
		undef $timeout{'ai_AutoSpeak'}{'time'};
	}
#mod Stop

	##########

	#DEBUG CODE
	if (time - $ai_v{'time'} > 2 && $config{'debug'}) {
		$stuff = @ai_seq_args;
		print "AI: @ai_seq | $stuff\n";
		$ai_v{'time'} = time;
	}

#mod Start
# Display Ai Queue
   $tbase =  sprintf("%.2f",$chars[$config{'char'}]{'exp'}/$chars[$config{'char'}]{'exp_max'} * 100) if $chars[$config{'char'}]{'exp_max'}; 
   $tjob = sprintf("%.2f",$chars[$config{'char'}]{'exp_job'}/$chars[$config{'char'}]{'exp_job_max'} * 100) if $chars[$config{'char'}]{'exp_job_max'}; 
   $tweight = int($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'} * 100)."%" if $chars[$config{'char'}]{'weight_max'}; 

	if ($stuff ne "$chars[$config{'char'}]{'name'} (B$chars[$config{'char'}]{'lv'}:$tbase J$chars[$config{'char'}]{'lv_job'}:$tjob) w$tweight $field{'name'} : $chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'}") {
		$stuff = "$chars[$config{'char'}]{'name'} (B$chars[$config{'char'}]{'lv'}:$tbase J$chars[$config{'char'}]{'lv_job'}:$tjob) w$tweight $field{'name'} : $chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'}";
		$CONSOLE->Title($stuff);
	}

#mod Stop

	if ($ai_v{'clear_aiQueue'}) {
		undef $ai_v{'clear_aiQueue'};
		undef @ai_seq;
		undef @ai_seq_args;
	}
	
}




#######################################
#######################################
#Parse Message
#######################################
#######################################



sub parseMsg {
	my $msg = shift;
	my $msg_size;

	if (length($msg) < 2) {
		return $msg;
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	if (length($msg) >= 4 && substr($msg,0,4) ne $accountID && $conState >= 4 && $lastswitch ne $switch
		&& length($msg) >= unpack("S1", substr($msg, 0, 2))) {
		decrypt(\$msg, $msg);
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	$switch_no = unpack("S1", substr($msg, 0, 2));

#mod Start
#Packet Debugger
	print "Packet Switch: $switch\n" if ($config{'debug'} >= 2 || $config{'debug_packet'} >= 3);
#mod Stop

	if ($lastswitch eq $switch && length($msg) > $lastMsgLength) {
		$errorCount++;
	} else {
		$errorCount = 0;
	}
	if ($errorCount > 3) {
		print "Caught unparsed packet error, potential loss of data.\n";

#mod Start 
#Packet Debugger I
		dumpData($lastPacket) if ($config{'debug_packet'} >= 2 && $lastPacket ne ""); 
		dumpData($msg) if ($config{'debug'} || $config{'debug_packet'}); 
		undef $lastPacket if ($config{'debug_packet'} >= 2);
#mod Stop

		$errorCount = 0;
		$msg_size = length($msg);
	}
	
	$lastswitch = $switch;

	if (substr($msg,0,4) ne $accountID || ($conState != 2 && $conState != 4)) {
			if ($rpackets{$switch} eq "-") {
				$msg_size = length($msg);
			} elsif ($rpackets{$switch} eq "0") {
				if (length($msg) < 4) {
					return $msg;
				}
				$msg_size = unpack("S1", substr($msg, 2, 2));
				if (length($msg) < $msg_size) {
					return $msg;
				}
			} elsif ($rpackets{$switch} > 1) {
				if (length($msg) < $rpackets{$switch}) {
					return $msg;
				}
				$msg_size = $rpackets{$switch};
			}else{
				dumpData($last_know_msg.$msg);
			}
			$last_know_msg = substr($msg, 0, $msg_size);
			$last_know_switch = $switch;
	}

	$lastMsgLength = length($msg);

	if (substr($msg,0,4) eq $accountID && ($conState == 2 || $conState == 4)) {
		if ($config{'encrypt'} && $conState == 4) {
			$encryptKey1 = unpack("L1", substr($msg, 6, 4));
			$encryptKey2 = unpack("L1", substr($msg, 10, 4));
			{
				use integer;
				$imult = (($encryptKey1 * $encryptKey2) + $encryptKey1) & 0xFF;
				$imult2 = ((($encryptKey1 * $encryptKey2) << 4) + $encryptKey2 + ($encryptKey1 * 2)) & 0xFF;
			}
			$encryptVal = $imult + ($imult2 << 8);
			$msg_size = 14;
		} else {
			$msg_size = 4;
		}
	} elsif ($switch eq "0069") {
		$conState = 2;
		undef $conState_tries;
		if ($versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$def_config/config.txt",\%config);
		}
		$sessionID = substr($msg, 4, 4);
		$accountID = substr($msg, 8, 4);
		$sessionID2 = substr($msg, 12, 4);
		$accountSex = unpack("C1",substr($msg, 46, 1));
		$accountSex2 = ($config{'sex'} ne "") ? $config{'sex'} : $accountSex;
		format ACCOUNT =
---------Account Info----------
Account ID: @<<<<<<<<<<<<<<<<<<
            getHex($accountID)
Sex:        @<<<<<<<<<<<<<<<<<<
            $sex_lut{$accountSex}
Session ID: @<<<<<<<<<<<<<<<<<<
            getHex($sessionID)
            @<<<<<<<<<<<<<<<<<<
            getHex($sessionID2) 
-------------------------------
.
		$~ = "ACCOUNT";
		write;
		$num = 0;
		undef @servers;
		for($i = 47; $i < $msg_size; $i+=32) {
			$servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
			$servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
			($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
			$servers[$num]{'users'} = unpack("S1",substr($msg, $i + 26, 2));
			$servers[$num]{'maintenance'} = unpack("S1",substr($msg, $i + 28, 2));
			$servers[$num]{'new'} = unpack("S1",substr($msg, $i + 30, 2));
			$num++;
		}
		$~ = "SERVERS";
		print "--------- Servers ----------\n";
		print "#         Name            Users  IP              Port  Main  new\n";
		for ($num = 0; $num < @servers; $num++) {
			format SERVERS =
@<< @<<<<<<<<<<<<<<<<<<<< @<<<<< @<<<<<<<<<<<<<< @<<<<<@<<<<<@<<<<<
$num  $servers[$num]{'name'}  $servers[$num]{'users'} $servers[$num]{'ip'} $servers[$num]{'port'} $servers[$num]{'maintenance'} $servers[$num]{'new'}
.
			write;
		}
		print "-------------------------------\n";
		print "Closing connection to Master Server\n";
		killConnection(\$remote_socket);
		if (!$config{'charServer_host'} && $config{'server'} eq "") {
			print "Choose your server.  Enter the server number:\n";
			$waitingForInput = 1;
		} elsif ($config{'charServer_host'}) {
			print "Forcing connect to char server $config{'charServer_host'}:$config{'charServer_port'}\n";
		} else {
			print "Server $config{'server'} selected\n";
		}
	} elsif ($switch eq "006A") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			print "Account name doesn't exist\n";
			print "Enter Username Again:\n";
			$input_socket->recv($msg, $MAX_READ);
			$config{'username'} = $msg;
			writeDataFileIntact("$def_config/config.txt", \%config);
		} elsif ($type == 1) {
			print "Password Error\n";
			print "Enter Password Again:\n";
			$input_socket->recv($msg, $MAX_READ);
			$config{'password'} = $msg;
			writeDataFileIntact("$def_config/config.txt", \%config);
		} elsif ($type == 3) {
			print "Server connection has been denied\n";
		} elsif ($type == 4) {
			print "Critical Error: Account has been disabled by evil Gravity\n";
			$quit = 1;
		} elsif ($type == 5) {
			print "Version $config{'version'} failed...trying to find version\n";
			$config{'version'}++;
			if (!$versionSearch) {
				$config{'version'} = 0;
				$versionSearch = 1;
			}
		} elsif ($type == 6) {
			print "The server is temporarily blocking your connection\n";
		}
		if ($type != 5 && $versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$def_config/config.txt", \%config);
		}

	} elsif ($switch eq "006B") {
		print "Recieved characters from Game Login Server\n";
		$conState = 3;
		undef $conState_tries;
		if ($config{"master_version_$config{'master'}"} == 0) {
			$startVal = 24;
		} else {
			$startVal = 4;
		}
		for($i = $startVal; $i < $msg_size; $i+=106) {

#exp display bugfix - chobit andy 20030129
			$num = unpack("C1", substr($msg, $i + 104, 1));
			$chars[$num]{'exp'} = unpack("L1", substr($msg, $i + 4, 4));
			$chars[$num]{'zenny'} = unpack("L1", substr($msg, $i + 8, 4));
			$chars[$num]{'exp_job'} = unpack("L1", substr($msg, $i + 12, 4));
			$chars[$num]{'lv_job'} = unpack("C1", substr($msg, $i + 16, 1));
			$chars[$num]{'hp'} = unpack("S1", substr($msg, $i + 42, 2));
			$chars[$num]{'hp_max'} = unpack("S1", substr($msg, $i + 44, 2));
			$chars[$num]{'sp'} = unpack("S1", substr($msg, $i + 46, 2));
			$chars[$num]{'sp_max'} = unpack("S1", substr($msg, $i + 48, 2));
			$chars[$num]{'jobID'} = unpack("C1", substr($msg, $i + 52, 1));
			$chars[$num]{'lv'} = unpack("C1", substr($msg, $i + 58, 1));
			($chars[$num]{'name'}) = substr($msg, $i + 74, 24) =~ /([\s\S]*?)\000/;
			$chars[$num]{'str'} = unpack("C1", substr($msg, $i + 98, 1));
			$chars[$num]{'agi'} = unpack("C1", substr($msg, $i + 99, 1));
			$chars[$num]{'vit'} = unpack("C1", substr($msg, $i + 100, 1));
			$chars[$num]{'int'} = unpack("C1", substr($msg, $i + 101, 1));
			$chars[$num]{'dex'} = unpack("C1", substr($msg, $i + 102, 1));
			$chars[$num]{'luk'} = unpack("C1", substr($msg, $i + 103, 1));
			$chars[$num]{'sex'} = $accountSex2;
		}
		$~ = "CHAR";
		for ($num = 0; $num < @chars; $num++) {
			format CHAR =
-------  Character @< ---------
         $num
Name: @<<<<<<<<<<<<<<<<<<<<<<<<
      $chars[$num]{'name'}
Job:  @<<<<<<<      Job Exp: @<<<<<<<
$jobs_lut{$chars[$num]{'jobID'}} $chars[$num]{'exp_job'}
Lv:   @<<<<<<<      Str: @<<<<<<<<
$chars[$num]{'lv'}  $chars[$num]{'str'}
J.Lv: @<<<<<<<      Agi: @<<<<<<<<
$chars[$num]{'lv_job'}  $chars[$num]{'agi'}
Exp:  @<<<<<<<      Vit: @<<<<<<<<
$chars[$num]{'exp'} $chars[$num]{'vit'}
HP:   @||||/@||||   Int: @<<<<<<<<
$chars[$num]{'hp'} $chars[$num]{'hp_max'} $chars[$num]{'int'}
SP:   @||||/@||||   Dex: @<<<<<<<<
$chars[$num]{'sp'} $chars[$num]{'sp_max'} $chars[$num]{'dex'}
Zenny: @<<<<<<<<<<  Luk: @<<<<<<<<
$chars[$num]{'zenny'} $chars[$num]{'luk'}
-------------------------------
.
			write;
		}
		if ($config{'char'} eq "") {
			print "Choose your character.  Enter the character number:\n";
			$waitingForInput = 1;
		} else {
			print "Character $config{'char'} selected\n";
			sendCharLogin(\$remote_socket, $config{'char'});
			$timeout{'gamelogin'}{'time'} = time;
		}

	} elsif ($switch eq "006C") {
		print "Error logging into Game Login Server (invalid character specified)...\n";
		$conState = 1;
		undef $conState_tries;

	} elsif ($switch eq "006E") {

	} elsif ($switch eq "0071") {
		print "Recieved character ID and Map IP from Game Login Server\n";
		$conState = 4;
		undef $conState_tries;
		$charID = substr($msg, 2, 4);
		($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;

		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
			chatLog("M","**Map : $field{'name'}\n");
		}

		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		format CHARINFO =
---------Game Info----------
Char ID: @<<<<<<<<<<<<<<<<<<
            getHex($charID)
MAP Name: @<<<<<<<<<<<<<<<<<<
            $map_name
MAP IP: @<<<<<<<<<<<<<<<<<<
            $map_ip
MAP Port: @<<<<<<<<<<<<<<<<<<
	$map_port
-------------------------------
.
		$~ = "CHARINFO";
		write;
		print "Closing connection to Game Login Server\n";
		killConnection(\$remote_socket);

	} elsif ($switch eq "0073") {
		$conState = 5;
		undef $conState_tries;
		makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));
		%{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
		print "You are now in the game\n";
		sendMapLoaded(\$remote_socket);
		sendLook(\$remote_socket,int(rand(8)),int(rand(3)));
#Mod Start
# Ignored Ppl
		if ($config{'ignoredAll'}) {
			print "Forcing Ignored-All...\n";
			sendIgnoreAll(\$remote_socket,0);
		}elsif (%ppl_control){
			print "Ignored Player in Ignored List....";
			 foreach $ppl ( keys %ppl_control ) {
				sendIgnore(\$remote_socket, $ppl, 0) if ($ppl_control{$ppl}{'ignored_auto'});
			 }
			 print "Done\n";
		}
#Mod Stop
		$timeout{'ai'}{'time'} = time;

	} elsif ($switch eq "0075") {

	} elsif ($switch eq "0077") {

	} elsif ($switch eq "0078" || $switch eq "01D8") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$sex = unpack("C*",substr($msg, 45,  1));
		$sitting = unpack("C*",substr($msg, 51,  1));
#mod Start
# Frozen Detect ( 2 = froze , 1 = Trap );
		$frozen = unpack("S*",substr($msg, 8, 2)); 
#mod Stop
		if ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "") 
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@petsID, $ID);
					$pets{$ID}{'nameID'} = $type;
					$pets{$ID}{'name'} = $display;
					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}
				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				print "Pet Exists: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "") 
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				}
#mod Start
# Add Frozen Field
				$monsters{$ID}{'frozen'} = $frozen;
#mod Stop
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;
				print "Monster Exists: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
			}

		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'sitting'} = $sitting > 0;
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

		} elsif ($type == 45) {
			if (!%{$portals{$ID}}) {
				$portals{$ID}{'appear_time'} = time;
				$nameID = unpack("L1", $ID);
				$exists = portalExists($field{'name'}, \%coords);
				$display = ($exists ne "") 
					? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
					: "Unknown ".$nameID;
				binAdd(\@portalsID, $ID);
				$portals{$ID}{'source'}{'map'} = $field{'name'};
				$portals{$ID}{'type'} = $type;
				$portals{$ID}{'nameID'} = $nameID;
				$portals{$ID}{'name'} = $display;
				$portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
			}
			%{$portals{$ID}{'pos'}} = %coords;
			print "Portal Exists: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n";

		} elsif ($type < 1000) {
			if (!%{$npcs{$ID}}) {
				$npcs{$ID}{'appear_time'} = time;
				$nameID = unpack("L1", $ID);
				$display = (%{$npcs_lut{$nameID}}) 
					? $npcs_lut{$nameID}{'name'}
					: "Unknown ".$nameID;
				binAdd(\@npcsID, $ID);
				$npcs{$ID}{'type'} = $type;
				$npcs{$ID}{'nameID'} = $nameID;
				$npcs{$ID}{'name'} = $display;
				$npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
			}
			%{$npcs{$ID}{'pos'}} = %coords;
			print "NPC Exists: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n";

		} else {
			print "Unknown Exists: $type - ".unpack("L*",$ID)."\n" if $config{'debug'};
		}

	} elsif ($switch eq "0079" || $switch eq "01D9") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S*",substr($msg, 14,  2));
		$sex = unpack("C*",substr($msg, 45,  1));
		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Connected: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

		} else {
			print "Unknown Connected: $type - ".getHex($ID)."\n" if $config{'debug'};
		}

	} elsif ($switch eq "007A") {

	} elsif ($switch eq "007B" || $switch eq "01DA") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$sex = unpack("C*",substr($msg, 49,  1));
		if ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "") 
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@petsID, $ID);
					$pets{$ID}{'nameID'} = $type;
					$pets{$ID}{'name'} = $display;
					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}
				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				if (%{$monsters{$ID}}) {
					binRemove(\@monstersID, $ID);
					undef %{$monsters{$ID}};
				}
				print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'appear_time'} = time;
					$monsters{$ID}{'nameID'} = $type;
					$display = ($monsters_lut{$type} ne "") 
						? $monsters_lut{$type}
						: "Unknown ".$type;
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
					print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				}
				%{$monsters{$ID}{'pos'}} = %coordsFrom;
				%{$monsters{$ID}{'pos_to'}} = %coordsTo;
				print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
			}
		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				
				print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if $config{'debug'};
			}
			%{$players{$ID}{'pos'}} = %coordsFrom;
			%{$players{$ID}{'pos_to'}} = %coordsTo;
			print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);
		} else {
			print "Unknown Moved: $type - ".getHex($ID)."\n" if $config{'debug'};
		}

	} elsif ($switch eq "007C") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 36, 3));
		$type = unpack("S*",substr($msg, 20,  2));
		$sex = unpack("C*",substr($msg, 35,  1));
		if ($type >= 1000) {
			if (!%{$monsters{$ID}}) {
				binAdd(\@monstersID, $ID);
				$monsters{$ID}{'nameID'} = $type;
				$monsters{$ID}{'appear_time'} = time;
				$display = ($monsters_lut{$monsters{$ID}{'nameID'}} ne "") 
						? $monsters_lut{$monsters{$ID}{'nameID'}}
						: "Unknown ".$monsters{$ID}{'nameID'};
				$monsters{$ID}{'name'} = $display;
				$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
			}
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
			print "Monster Spawned: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Spawned: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
		} else {
			print "Unknown Spawned: $type - ".getHex($ID)."\n" if $config{'debug'};
		}

	} elsif ($switch eq "007F") {
		$time = unpack("L1",substr($msg, 2, 4));
		print "Recieved Sync\n" if ($config{'debug'} >= 2);
		$timeout{'play'}{'time'} = time;
	
	} elsif ($switch eq "0080") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 6, 1));
		
		if ($ID eq $accountID) {
			print "You have died\n";
			$chars[$config{'char'}]{'dead'} = 1;
			$chars[$config{'char'}]{'dead_time'} = time;
		} elsif (%{$monsters{$ID}}) {
			%{$monsters_old{$ID}} = %{$monsters{$ID}};
			$monsters_old{$ID}{'gone_time'} = time;
			if ($type == 0) {
				print "Monster Disappeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				$monsters_old{$ID}{'disappeared'} = 1;

			} elsif ($type == 1) {
				print "Monster Died: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				$monsters_old{$ID}{'dead'} = 1;
			}
			binRemove(\@monstersID, $ID);
			undef %{$monsters{$ID}};
		} elsif (%{$players{$ID}}) {
			if ($type == 0) {
				print "Player Disappeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disappeared'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
#mod Start
				if (%{$venderLists{$ID}}) {
					binRemove(\@venderListsID, $ID); 
					undef %{$venderLists{$ID}}; 
				}
#mod Stop
			} elsif ($type == 1) {
				print "Player Died: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n";
				$players{$ID}{'dead'} = 1;
			} elsif ($type == 2) {
				print "Player Disconnected: $players{$ID}{'name'}\n" if $config{'debug'};
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disconnected'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
#mod Start
				if (%{$venderLists{$ID}}) {
					binRemove(\@venderListsID, $ID); 
					undef %{$venderLists{$ID}}; 
				}
#mod Stop
			}
		} elsif (%{$players_old{$ID}}) {
			if ($type == 2) {
				print "Player Disconnected: $players_old{$ID}{'name'}\n" if $config{'debug'};
				$players_old{$ID}{'disconnected'} = 1;
				if (%{$venderLists{$ID}}) {
					binRemove(\@venderListsID, $ID); 
					undef %{$venderLists{$ID}}; 
				}
			} elsif ($type == 3) {
				print "Player Teleported: $players{$ID}{'name'}\n" if $config{'debug'};
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disconnected'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
				if (%{$venderLists{$ID}}) {
					binRemove(\@venderListsID, $ID); 
					undef %{$venderLists{$ID}}; 
				}
			}
		} elsif (%{$portals{$ID}}) {
			print "Portal Disappeared: $portals{$ID}{'name'} ($portals{$ID}{'binID'})\n" if ($config{'debug'});
			%{$portals_old{$ID}} = %{$portals{$ID}};
			$portals_old{$ID}{'disappeared'} = 1;
			$portals_old{$ID}{'gone_time'} = time;
			binRemove(\@portalsID, $ID);
			undef %{$portals{$ID}};
		} elsif (%{$npcs{$ID}}) {
			print "NPC Disappeared: $npcs{$ID}{'name'} ($npcs{$ID}{'binID'})\n" if ($config{'debug'});
			%{$npcs_old{$ID}} = %{$npcs{$ID}};
			$npcs_old{$ID}{'disappeared'} = 1;
			$npcs_old{$ID}{'gone_time'} = time;
			binRemove(\@npcsID, $ID);
			undef %{$npcs{$ID}};
		} elsif (%{$pets{$ID}}) {
			undef %{$chars[$config{'char'}]{'pet'}} if ($chars[$config{'char'}]{'pet'}{'ID'} == $ID);
			print "Pet Disappeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			binRemove(\@petsID, $ID);
			undef %{$pets{$ID}};
		} else {
			print "Unknown Disappeared: ".getHex($ID)."\n" if $config{'debug'};
		}

	} elsif ($switch eq "0081") {
		$type = unpack("C1", substr($msg, 2, 1));
		$conState = 1;
		undef $conState_tries;
		if ($type == 2) {
			print "Critical Error: Dual login prohibited - Someone trying to login!\n";
			if ($config{'dcOnDualLogin'} == 1) {
				print "Disconnect immediately!\n";
				$quit = 1;
			} elsif ($config{'dcOnDualLogin'} >= 2) {
				print "Disconnect for $config{'dcOnDualLogin'} seconds...\n";
				$timeout_ex{'master'}{'time'} = time;
				$timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
			}

		} elsif ($type == 3) {
			print "Error: Out of sync with server\n";
		} elsif ($type == 5) {
			print "Critical Error: Your age under 18\n";
			$quit = 1;
		} elsif ($type == 6) {
			print "Critical Error: You must pay to play this account!\n";
			$quit = 1;
		} elsif ($type == 8) {
			print "Error: The server still recognizes your last connection\n";
		}

	} elsif ($switch eq "0087") {
		makeCoords(\%coordsFrom, substr($msg, 6, 3));
		makeCoords2(\%coordsTo, substr($msg, 8, 3));
		%{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
		%{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;
		print "You move to $field{'name'} : $coordsTo{'x'}, $coordsTo{'y'}\n" if ($config{'debug'} == 1);
		$chars[$config{'char'}]{'time_move'} = time;
		$chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * $config{'seconds_per_block'};

	} elsif ($switch eq "0088") {
		undef $level_real;
		# Long distance attack solution 
		$ID = substr($msg, 2, 4); 
		undef %coords; 
		$coords{'x'} = unpack("S1", substr($msg, 6, 2)); 
		$coords{'y'} = unpack("S1", substr($msg, 8, 2)); 
		if ($ID eq $accountID) { 
#			%{$chars[$config{'char'}]{'pos'}} = %coords; 
#			%{$chars[$config{'char'}]{'pos_to'}} = %coords; 
			print "Movement interrupted, your coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'}; 
#			aiRemove("move"); 
		} elsif (%{$monsters{$ID}}) { 
			%{$monsters{$ID}{'pos'}} = %coords; 
			%{$monsters{$ID}{'pos_to'}} = %coords; 
		} elsif (%{$players{$ID}}) { 
			%{$players{$ID}{'pos'}} = %coords; 
			%{$players{$ID}{'pos_to'}} = %coords; 
#		} else { 
#			dumpData(substr($msg, 0, 10)) if ($config{'debug_packet'} >= 2); 
		} 

	} elsif ($switch eq "0089") {

	} elsif ($switch eq "008A") {
		$ID1 = substr($msg, 2, 4);
		$ID2 = substr($msg, 6, 4);
		$standing = unpack("C1", substr($msg, 26, 2)) - 2;
		$damage = unpack("S1", substr($msg, 22, 2));
		$type = unpack("C1",substr($msg,26,1));
		if ($damage == 0) {
			$dmgdisplay = "Miss!";
		} else {
			$dmgdisplay = $damage;
			$dmgdisplay .= "!" if ($type==10);
		}
		updateDamageTables($ID1, $ID2, $damage);
		if ($ID1 eq $accountID) {
			if (%{$monsters{$ID2}}) {
#mod Start
# Display Hp / Sp when Attack & Avoid Miss
#				if ($config{'dcOnAtkMiss'} && $monsters{$ID2}{'missedFromYou'}) {
#				}
				$CONSOLE->Attr($FG_BROWN|$BG_BLACK) if ($dmgdisplay ne "Miss!" && $config{'colorMode'}) ;
				print sprintf("[Hp:%3d|Sp:%3d]"
						,int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
						,int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100))
						,"Attack Monster: $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - Dmg: $dmgdisplay\n";
				$CONSOLE->Attr($FG_GRAY) if ($dmgdisplay ne "Miss!" && $config{'colorMode'});
#mod Stop
			} elsif (%{$items{$ID2}}) {
				print "You pick up Item: $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if $config{'debug'};
				$items{$ID2}{'takenBy'} = $accountID;
			} elsif ($ID2 == 0) {
				if ($standing) {
					$chars[$config{'char'}]{'sitting'} = 0;
					print "You're Standing\n";
				} else {
					$chars[$config{'char'}]{'sitting'} = 1;
					print "You're Sitting\n";
				}
			}
		} elsif ($ID2 eq $accountID) {
			if (%{$monsters{$ID1}}) {
#mod Start
# Display Hp / Sp when Damage
				$CONSOLE->Attr($FG_LIGHTRED|$BG_BLACK) if ($dmgdisplay ne "Miss!" && $config{'colorMode'});
				print sprintf("[Hp:%3d|Sp:%3d]"
						,int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
						,int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100))
						,"Get Dmg : $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) - Dmg: $dmgdisplay\n";
				$CONSOLE->Attr($FG_GRAY) if ($dmgdisplay ne "Miss!" && $config{'colorMode'});
				useTeleport(1) if ($monsters{$ID1}{'name'} eq "" || ($config{'teleportAuto_Dmg'} && $dmgdisplay >= $config{'teleportAuto_Dmg'}));
#mod Stop
			}
			undef $chars[$config{'char'}]{'time_cast'};
		} elsif (%{$monsters{$ID1}}) {
			if (%{$players{$ID2}}) {
				print "Monster $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) attacks Player $players{$ID2}{'name'} ($players{$ID2}{'binID'}) - Dmg: $dmgdisplay\n" if ($config{'debug'});
			}
			
		} elsif (%{$players{$ID1}}) {
			if (%{$monsters{$ID2}}) {
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) attacks Monster $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - Dmg: $dmgdisplay\n" if ($config{'debug'});
			} elsif (%{$items{$ID2}}) {
				$items{$ID2}{'takenBy'} = $ID1;
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
			} elsif ($ID2 == 0) {
				if ($standing) {
					$players{$ID1}{'sitting'} = 0;
					print "Player is Standing: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
				} else {
					$players{$ID1}{'sitting'} = 1;
					print "Player is Sitting: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
				}
			}
		} else {
			print "Unknown ".getHex($ID1)." attacks ".getHex($ID2)." - Dmg: $dmgdisplay\n" if $config{'debug'};
		}

	} elsif ($switch eq "008D") {
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 8, $msg_size - 8);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("c", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "c";
		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
		print "$chat\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	} elsif ($switch eq "008E") {
		$chat = substr($msg, 4, $msg_size - 5);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("c", $chat."\n");
		$CONSOLE->Attr($FG_YELLOW|$BG_BLACK) if ($config{'colorMode'});
		print "$chat\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	} elsif ($switch eq "008F") {

	} elsif ($switch eq "0091") {
		initMapChangeVars();
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
#mod Start
#Avoid Map & Map log
			chatLog("M","**Map : $field{'name'}\n");
#			if (existsInList($config{"AvoidMap"}, $field{'name'})) {
#				useTeleport(2);
#			}

#mod Stop
		}
		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
		%{$chars[$config{'char'}]{'pos'}} = %coords;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords;
		$CONSOLE->Attr($FG_LIGHTCYAN |$BG_BLACK) if ($config{'colorMode'});
		print "Map Change: $map_name\n";
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
		print "Sending Map Loaded\n" if $config{'debug'};
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		sendMapLoaded(\$remote_socket);

	} elsif ($switch eq "0092") {
		$conState = 4;
		undef $conState_tries;
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
#mod Start
#AvoidMap & Map Log
			chatLog("M","**Map : $field{'name'}\n");
#			if (existsInList($config{"AvoidMap"}, $field{'name'})) {
#				useTeleport(2);
#			}
#mod Stop
		}
		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		format MAPINFO =
---------Map Change Info----------
MAP Name: @<<<<<<<<<<<<<<<<<<
            $map_name
MAP IP: @<<<<<<<<<<<<<<<<<<
            $map_ip
MAP Port: @<<<<<<<<<<<<<<<<<<
	$map_port
-------------------------------
.
		$~ = "MAPINFO";
		write;
		print "Closing connection to Map Server\n";
		killConnection(\$remote_socket);

	} elsif ($switch eq "0093") {

	} elsif ($switch eq "0095") {
		$ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@playersID, $ID);
				print "Player Info: $players{$ID}{'name'} ($binID)\n";
			}
		}
		if (%{$monsters{$ID}}) {
			($monsters{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@monstersID, $ID);
				print "Monster Info: $monsters{$ID}{'name'} ($binID)\n";
			}
			if ($monsters_lut{$monsters{$ID}{'nameID'}} eq "") {
				$monsters_lut{$monsters{$ID}{'nameID'}} = $monsters{$ID}{'name'};
				updateMonsterLUT("$def_table/monsters.txt", $monsters{$ID}{'nameID'}, $monsters{$ID}{'name'});
			}
		}
		if (%{$npcs{$ID}}) {
			($npcs{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/; 
			if ($config{'debug'} >= 2) { 
				$binID = binFind(\@npcsID, $ID); 
				print "NPC Info: $npcs{$ID}{'name'} ($binID)\n"; 
			}
			if (!%{$npcs_lut{$npcs{$ID}{'nameID'}}}) {
				$npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
				$npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $field{'name'};
				%{$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}} = %{$npcs{$ID}{'pos'}};
				updateNPCLUT("$def_table/npcs.txt", $npcs{$ID}{'nameID'}, $field{'name'}, $npcs{$ID}{'pos'}{'x'}, $npcs{$ID}{'pos'}{'y'}, $npcs{$ID}{'name'}); 
			}
		}
		if (%{$pets{$ID}}) {
			($pets{$ID}{'name_given'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@petsID, $ID);
				print "Pet Info: $pets{$ID}{'name_given'} ($binID)\n";
			}
		}

	} elsif ($switch eq "0096") {

	} elsif ($switch eq "0097") {
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$privMsg = substr($msg, 28, $msg_size - 29);
		if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
			$privMsgUsers[@privMsgUsers] = $privMsgUser;
		}
		chatLog("pm", "(From: $privMsgUser) : $privMsg\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "pm";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $privMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $privMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
		print "(From: $privMsgUser) : $privMsg\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	} elsif ($switch eq "0098") {
		$type = unpack("C1",substr($msg, 2, 1));
		$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
		if ($type == 0) {
			print "(To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n";
			chatLog("pm", "(To: $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n");
		} elsif ($type == 1) {
			print "$lastpm[0]{'user'} is not online\n";
		} elsif ($type == 2) {
			print "Player can't hear you - you are ignored\n";
		}
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		shift @lastpm;
		$msg_size = 3;

	} elsif ($switch eq "009A") {
		$chat = substr($msg, 4, $msg_size - 5);
		chatLog("s", $chat."\n");
		$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
		print "$chat\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		

	} elsif ($switch eq "009C") {
		$ID = substr($msg, 2, 4);
		$body = unpack("C1",substr($msg, 8, 1));
		$head = unpack("C1",substr($msg, 6, 1));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'look'}{'head'} = $head;
			$chars[$config{'char'}]{'look'}{'body'} = $body;
			print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);

		} elsif (%{$players{$ID}}) {
			$players{$ID}{'look'}{'head'} = $head;
			$players{$ID}{'look'}{'body'} = $body;
			print "Player $players{$ID}{'name'} ($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);

		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'look'}{'head'} = $head;
			$monsters{$ID}{'look'}{'body'} = $body;
			print "Monster $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		}

	} elsif ($switch eq "009D") {
		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$x = unpack("S1", substr($msg, 9, 2));
		$y = unpack("S1", substr($msg, 11, 2));
		$amount = unpack("S1", substr($msg, 13, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "") 
				? $items_lut{$items{$ID}{'nameID'}}
				: "Unknown ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "Item Exists: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n";

	} elsif ($switch eq "009E") {
		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$x = unpack("S1", substr($msg, 9, 2));
		$y = unpack("S1", substr($msg, 11, 2));
		$amount = unpack("S1", substr($msg, 15, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "") 
				? $items_lut{$items{$ID}{'nameID'}}
				: "Unknown ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "Item Appeared: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n";
#mod Start
# Take Item in the Air
		if ($itemsPickup{lc($items{$ID}{'name'})}==2 && distance(\%{$items{$ID}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}})<=5) {
			$items{'takefirst'}=$items{$ID}{'name'};
			sendTake(\$remote_socket, $ID);
		}
#mod Stop

	} elsif ($switch eq "00A0") {
#	00a0 <index>.w <amount>.w <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w <equip type>.w <type>.B <fail>.B
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$ID = unpack("S1",substr($msg, 6, 2));
		$type = unpack("C1",substr($msg, 21, 1));
		$type_equip = unpack("S1",substr($msg, 19, 2));
		$fail = unpack("C1",substr($msg, 22, 1));
		undef $invIndex;
#mod Start
#Search with index, not name! Otherwise non-stackable item will screw it up!
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
#mod Stop
		if ($fail == 0) {
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = $type;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $type_equip;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
#mod Start
# parse Card & Elements
				#------------------------------------------------------------------------------------------------------------
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, 10, 1));
					if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = unpack("C1", substr($msg, 13, 1));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
					} else {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
					}
				}
				#------------------------------------------------------------------------------------------------------------
#mod Stop
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
			}
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
#mod Start
#modify name & take items in the air II
			modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
			if ($items{'takefirst'} ne "") {
				chatLog("i"," Get Item : $display ($invIndex) x $amount \n");
				alertsound($config{'alertSound_name'},$config{'alertSound_volume'}) if ($config{'alertSound'});
				$items{'takefirst'} = "";
			}
# mod Stop
			$CONSOLE->Attr($FG_LIGHTGREEN|$BG_BLACK) if ($config{'colorMode'});
			print "Item added to inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n";
#mod Start
#Auto - Drop
			if ($itemsPickup{lc($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}})} eq "0") {
				sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $amount);
				print "Auto-Drop Item : $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount \n";
			}
#mod Stop
			$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		} elsif ($fail == 6) {
			print "Can't loot item...wait...\n";
		}

	} elsif ($switch eq "00A1") {
		$ID = substr($msg, 2, 4);
		if (%{$items{$ID}}) {
			print "Item Disappeared: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
			%{$items_old{$ID}} = %{$items{$ID}};
			$items_old{$ID}{'disappeared'} = 1;
			$items_old{$ID}{'gone_time'} = time;
			undef %{$items{$ID}};
			binRemove(\@itemsID, $ID);
		}

	} elsif ($switch eq "00A3") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef $invIndex;
		for($i = 4; $i < $msg_size; $i+=10) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};	
		}

	} elsif ($switch eq "00A4") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef $invIndex;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = 1;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
#mod Start
# Parse Card & Element
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, $i + 11, 1)); 
			if(unpack("S1", substr($msg,$i+12, 2)) == 0x00FF){ 
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = unpack("C1", substr($msg,$i+14, 1)); 
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'} = unpack("C1", substr($msg,$i+15, 1)) / 0x05; 
			}else{
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0] = unpack("S1", substr($msg,$i+12, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1] = unpack("S1", substr($msg,$i+14, 2)); 
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2] = unpack("S1", substr($msg,$i+16, 2)); 
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3] = unpack("S1", substr($msg,$i+18, 2)); 
			}
			modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]}); 
#mod Stop
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'}}\n" if $config{'debug'};
		}

	} elsif ($switch eq "00A5") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef %storage;
		undef @storageID;
		for($i = 4; $i < $msg_size; $i+=10) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			binAdd(\@storageID, $ID);
			$storage{$ID}{'index'} = $index;
			$storage{$ID}{'nameID'} = $ID;
			$storage{$ID}{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{$ID}{'name'} = $display;
			$storage{$ID}{'binID'} = binFind(\@storageID, $ID);
			print "Storage: $storage{$ID}{'name'} ($storage{$ID}{'binID'})\n" if $config{'debug'};
		}
		print "Storage opened\n";
	} elsif ($switch eq "00A6") {
#<index>.w <item ID>.w <type>.B <identify flag>.B <equip type>.w <equip point>.w <attribute?>.B <refine>.B <card>.4w
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4)); 
 		$msg = substr($msg, 0, 4).$newmsg; 

		for($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			binAdd(\@storageID, $index);
			$storage{$index}{'index'} = $index;
			$storage{$index}{'nameID'} = $ID;
			$storage{$index}{'amount'} = 1;
			$storage{$index}{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$storage{$index}{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$storage{$index}{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$storage{$index}{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{$index}{'name'} = $display;
			$storage{$index}{'binID'} = binFind(\@storageID, $index);
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			$storage{$index}{'refined'} = unpack("C1", substr($msg, $i+11, 1));
			if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
				$storage{$index}{'elements'} = unpack("C1", substr($msg, $i+14, 1));
				$storage{$index}{'star'}        = unpack("C1", substr($msg, $i+15, 1));
			} else {
				$storage{$index}{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
				$storage{$index}{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
				$storage{$index}{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
				$storage{$index}{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
			}
			modifingName(\%{$storage{$index}});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
			print "Storage Item: $storage{$index}{'name'} ($index) x $storage{$index}{'amount'}\n" if $config{'debug'};
		}

	} elsif ($switch eq "00A8") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
		print "You used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}

	} elsif ($switch eq "00AA") {
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail == 0) {
			print "You can't put on $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} else {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $type;
			print "You equip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$type} ($type)\n";
		}

	} elsif ($switch eq "00AC") {
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail ==0) {
			print "You can't unequip on $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		}else{
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'}=0;
			print "You unequip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$type} ($type)\n";
		}

	} elsif ($switch eq "00AF") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		print "Inventory Item Removed: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}

	} elsif ($switch eq "00B0") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));
		if ($type == 0) {
			print "Something1: $val\n" if $config{'debug'};
		} elsif ($type == 3) {
			print "Something2: $val\n" if $config{'debug'};
		} elsif ($type == 5) {
			$chars[$config{'char'}]{'hp'} = $val;
			print "Hp: $val\n" if $config{'debug'};
		} elsif ($type == 6) {
			$chars[$config{'char'}]{'hp_max'} = $val;
			print "Max Hp: $val\n" if $config{'debug'};
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} = $val;
			print "Sp: $val\n" if $config{'debug'};
		} elsif ($type == 8) {
			$chars[$config{'char'}]{'sp_max'} = $val;
			print "Max Sp: $val\n" if $config{'debug'};
		} elsif ($type == 9) {
			$chars[$config{'char'}]{'points_free'} = $val;
			print "Status Points: $val\n" if $config{'debug'};
		} elsif ($type == 11) {
			$chars[$config{'char'}]{'lv'} = $val;
			print "Level: $val\n" if $config{'debug'};
		} elsif ($type == 12) {
			$chars[$config{'char'}]{'points_skill'} = $val;
			print "Skill Points: $val\n" if $config{'debug'};
		} elsif ($type == 24) {
			$chars[$config{'char'}]{'weight'} = int($val / 10);
			print "Weight: $chars[$config{'char'}]{'weight'}\n" if $config{'debug'};
		} elsif ($type == 25) {
			$chars[$config{'char'}]{'weight_max'} = int($val / 10);
			print "Max Weight: $chars[$config{'char'}]{'weight_max'}\n" if $config{'debug'};
		} elsif ($type == 41) {
			$chars[$config{'char'}]{'attack'} = $val;
			print "Attack: $val\n" if $config{'debug'};
		} elsif ($type == 42) {
			$chars[$config{'char'}]{'attack_bonus'} = $val;
			print "Attack Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 43) {
			$chars[$config{'char'}]{'attack_magic_min'} = $val;
			print "Magic Attack Min: $val\n" if $config{'debug'};
		} elsif ($type == 44) {
			$chars[$config{'char'}]{'attack_magic_max'} = $val;
			print "Magic Attack Max: $val\n" if $config{'debug'};
		} elsif ($type == 45) {
			$chars[$config{'char'}]{'def'} = $val;
			print "Defense: $val\n" if $config{'debug'};
		} elsif ($type == 46) {
			$chars[$config{'char'}]{'def_bonus'} = $val;
			print "Defense Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 47) {
			$chars[$config{'char'}]{'def_magic'} = $val;
			print "Magic Defense: $val\n" if $config{'debug'};
		} elsif ($type == 48) {
			$chars[$config{'char'}]{'def_magic_bonus'} = $val;
			print "Magic Defense Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 49) {
			$chars[$config{'char'}]{'hit'} = $val;
			print "Hit: $val\n" if $config{'debug'};
		} elsif ($type == 50) {
			$chars[$config{'char'}]{'flee'} = $val;
			print "Flee: $val\n" if $config{'debug'};
		} elsif ($type == 51) {
			$chars[$config{'char'}]{'flee_bonus'} = $val;
			print "Flee Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 52) {
			$chars[$config{'char'}]{'critical'} = $val;
			print "Critical: $val\n" if $config{'debug'};
		} elsif ($type == 53) { 
			$chars[$config{'char'}]{'attack_speed'} = 200 - $val/10; 
			print "Attack Speed: $chars[$config{'char'}]{'attack_speed'}\n" if $config{'debug'};
		} elsif ($type == 55) {
			$chars[$config{'char'}]{'lv_job'} = $val;
			print "Job Level: $val\n" if $config{'debug'};
		} elsif ($type == 124) {
			print "Something3: $val\n" if $config{'debug'};
		} else {
			print "Something: $val\n" if $config{'debug'};
		}

	} elsif ($switch eq "00B1") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));
		if ($type == 1) {
			$chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
			$chars[$config{'char'}]{'exp'} = $val;
			print "Exp: $val\n" if $config{'debug'}; 
		} elsif ($type == 2) {
			$chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
			$chars[$config{'char'}]{'exp_job'} = $val;
			print "Job Exp: $val\n" if $config{'debug'};
		} elsif ($type == 20) {
			$chars[$config{'char'}]{'zenny'} = $val;
			print "Zenny: $val\n" if $config{'debug'};
		} elsif ($type == 22) {
			$chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
			$chars[$config{'char'}]{'exp_max'} = $val;
			print "Required Exp: $val\n" if $config{'debug'};
		} elsif ($type == 23) {
			$chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
			$chars[$config{'char'}]{'exp_job_max'} = $val;
			print "Required Job Exp: $val\n" if $config{'debug'};
		}

	} elsif ($switch eq "00B4") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		$talk{'ID'} = $ID;
		$talk{'nameID'} = unpack("L1", $ID);
		$talk{'msg'} = $talk;
		print "$npcs{$ID}{'name'} : $talk{'msg'}\n";

	} elsif ($switch eq "00B5") {
		$ID = substr($msg, 2, 4);
		print "$npcs{$ID}{'name'} : Type 'talk cont' to continue talking\n";

	} elsif ($switch eq "00B6") {
		$ID = substr($msg, 2, 4);
		undef %talk;
		print "$npcs{$ID}{'name'} : Done talking\n";
		sendTalkCancel(\$remote_socket,$ID);
	} elsif ($switch eq "00B7" ) {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		@preTalkResponses = split /:/, $talk;
		undef @{$talk{'responses'}};
		foreach (@preTalkResponses) {
			push @{$talk{'responses'}}, $_ if $_ ne "";
		}
		$talk{'responses'}[@{$talk{'responses'}}] = "Cancel Chat";
		print "$npcs{$ID}{'name'} : Type 'talk resp' and choose a response.\n";
	
	} elsif ($switch eq "00BC") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 5, 1));
		if ($val == 207) {
			print "Not enough stat points to add\n";
		} else {
			if ($type == 13) {
				$chars[$config{'char'}]{'str'} = $val;
				print "Strength: $val\n" if $config{'debug'};
			} elsif ($type == 14) {
				$chars[$config{'char'}]{'agi'} = $val;
				print "Agility: $val\n" if $config{'debug'};
			} elsif ($type == 15) {
				$chars[$config{'char'}]{'vit'} = $val;
				print "Vitality: $val\n" if $config{'debug'};
			} elsif ($type == 16) {
				$chars[$config{'char'}]{'int'} = $val;
				print "Intelligence: $val\n" if $config{'debug'};
			} elsif ($type == 17) {
				$chars[$config{'char'}]{'dex'} = $val;
				print "Dexterity: $val\n" if $config{'debug'};
			} elsif ($type == 18) {
				$chars[$config{'char'}]{'luk'} = $val;
				print "Luck: $val\n" if $config{'debug'};
			} else {
				print "Something: $val\n";
			}
		}

	} elsif ($switch eq "00BD") {
		$chars[$config{'char'}]{'points_free'} = unpack("S1", substr($msg, 2, 2));
		$chars[$config{'char'}]{'str'} = unpack("C1", substr($msg, 4, 1));
		$chars[$config{'char'}]{'points_str'} = unpack("C1", substr($msg, 5, 1));
		$chars[$config{'char'}]{'agi'} = unpack("C1", substr($msg, 6, 1));
		$chars[$config{'char'}]{'points_agi'} = unpack("C1", substr($msg, 7, 1));
		$chars[$config{'char'}]{'vit'} = unpack("C1", substr($msg, 8, 1));
		$chars[$config{'char'}]{'points_vit'} = unpack("C1", substr($msg, 9, 1));
		$chars[$config{'char'}]{'int'} = unpack("C1", substr($msg, 10, 1));
		$chars[$config{'char'}]{'points_int'} = unpack("C1", substr($msg, 11, 1));
		$chars[$config{'char'}]{'dex'} = unpack("C1", substr($msg, 12, 1));
		$chars[$config{'char'}]{'points_dex'} = unpack("C1", substr($msg, 13, 1));
		$chars[$config{'char'}]{'luk'} = unpack("C1", substr($msg, 14, 1));
		$chars[$config{'char'}]{'points_luk'} = unpack("C1", substr($msg, 15, 1));
		$chars[$config{'char'}]{'attack'} = unpack("S1", substr($msg, 16, 2));
		$chars[$config{'char'}]{'attack_bonus'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 20, 2));
		$chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 22, 2));
		$chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
		$chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
		$chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
		$chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
		$chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
		$chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
		$chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
		$chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
		print	"Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
			,"Agility: $chars[$config{'char'}]{'agi'} #$chars[$config{'char'}]{'points_agi'}\n"
			,"Vitality: $chars[$config{'char'}]{'vit'} #$chars[$config{'char'}]{'points_vit'}\n"
			,"Intelligence: $chars[$config{'char'}]{'int'} #$chars[$config{'char'}]{'points_int'}\n"
			,"Dexterity: $chars[$config{'char'}]{'dex'} #$chars[$config{'char'}]{'points_dex'}\n"
			,"Luck: $chars[$config{'char'}]{'luk'} #$chars[$config{'char'}]{'points_luk'}\n"
			,"Attack: $chars[$config{'char'}]{'attack'}\n"
			,"Attack Bonus: $chars[$config{'char'}]{'attack_bonus'}\n"
			,"Magic Attack Min: $chars[$config{'char'}]{'attack_magic_min'}\n"
			,"Magic Attack Max: $chars[$config{'char'}]{'attack_magic_max'}\n"
			,"Defense: $chars[$config{'char'}]{'def'}\n"
			,"Defense Bonus: $chars[$config{'char'}]{'def_bonus'}\n"
			,"Magic Defense: $chars[$config{'char'}]{'def_magic'}\n"
			,"Magic Defense Bonus: $chars[$config{'char'}]{'def_magic_bonus'}\n"
			,"Hit: $chars[$config{'char'}]{'hit'}\n"
			,"Flee: $chars[$config{'char'}]{'flee'}\n"
			,"Flee Bonus: $chars[$config{'char'}]{'flee_bonus'}\n"
			,"Critical: $chars[$config{'char'}]{'critical'}\n"
			,"Status Points: $chars[$config{'char'}]{'points_free'}\n"
			if $config{'debug'};

	} elsif ($switch eq "00BE") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 4, 1));
		if ($type == 32) {
			$chars[$config{'char'}]{'points_str'} = $val;
			print "Points needed for Strength: $val\n" if $config{'debug'};
		} elsif ($type == 33) {
			$chars[$config{'char'}]{'points_agi'} = $val;
			print "Points needed for Agility: $val\n" if $config{'debug'};
		} elsif ($type == 34) {
			$chars[$config{'char'}]{'points_vit'} = $val;
			print "Points needed for Vitality: $val\n" if $config{'debug'};
		} elsif ($type == 35) {
			$chars[$config{'char'}]{'points_int'} = $val;
			print "Points needed for Intelligence: $val\n" if $config{'debug'};
		} elsif ($type == 36) {
			$chars[$config{'char'}]{'points_dex'} = $val;
			print "Points needed for Dexterity: $val\n" if $config{'debug'};
		} elsif ($type == 37) {
			$chars[$config{'char'}]{'points_luk'} = $val;
			print "Points needed for Luck: $val\n" if $config{'debug'};
		}
	} elsif ($switch eq "00C0") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C*", substr($msg, 6, 1));
#mod Start
# add Emotion to Ai TalkQueue
		undef $chat;
		if ($ID eq $accountID) {
			$chat = "$chars[$config{'char'}]{'name'} : $emotions_lut{$type}";
		} elsif (%{$players{$ID}}) {
			$chat = "$players{$ID}{'name'} : $emotions_lut{$type}";
			$ai_cmdQue[$ai_cmdQue]{'type'} = "e";
			$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
			$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$ID}{'name'};
			$ai_cmdQue[$ai_cmdQue]{'msg'} = "/emo".$type;
			$ai_cmdQue[$ai_cmdQue]{'time'} = time;
			$ai_cmdQue++;
		} elsif (%{$monsters{$ID}}){
			$chat = "$monsters{$ID}{'name'} : $emotions_lut{$type}";
		}
		$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
		print "$chat\n" if ($chat);
		chatLog("e", "$chat\n") if ($config{'chatlog_emo'});
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
#mod Stop

	} elsif ($switch eq "00C1") {

	} elsif ($switch eq "00C2") {
		$users = unpack("L*", substr($msg, 2, 4));
		print "There are currently $users users online\n";


	} elsif ($switch eq "00C3") {

	} elsif ($switch eq "00C4") {
		$ID = substr($msg, 2, 4);
		undef %talk;
		$talk{'buyOrSell'} = 1;
		$talk{'ID'} = $ID;
		print "$npcs{$ID}{'name'} : Type 'store' to start buying, or type 'sell' to start selling\n";

	} elsif ($switch eq "00C6") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @storeList;
		$storeList = 0;
		undef $talk{'buyOrSell'};
		for ($i = 4; $i < $msg_size; $i+=11) {
			$price = unpack("L1", substr($msg, $i, 4));
			$type = unpack("C1", substr($msg, $i + 8, 1));
			$ID = unpack("S1", substr($msg, $i + 9, 2));
			$storeList[$storeList]{'nameID'} = $ID;
			$display = ($items_lut{$ID} ne "") 
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storeList[$storeList]{'name'} = $display;
			$storeList[$storeList]{'nameID'} = $ID;
			$storeList[$storeList]{'type'} = $type;
			$storeList[$storeList]{'price'} = $price;
			print "Item added to Store: $storeList[$storeList]{'name'} - $price z\n" if ($config{'debug'} >= 2);
			$storeList++;
		}
		print "$npcs{$talk{'ID'}}{'name'} : Check my store list by typing 'store'\n";
	} elsif ($switch eq "00C7") {
		#sell list, similar to buy list
		if (length($msg) > 4) {
			decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
			$msg = substr($msg, 0, 4).$newmsg;
		}
		undef $talk{'buyOrSell'};
		print "Ready to start selling items\n";
	} elsif ($switch eq "00CA") {

	} elsif ($switch eq "00CB") {

	} elsif ($switch eq "00D1") {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "Player ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "Player unignored\n";
			}
		}

	} elsif ($switch eq "00D2") {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "All Players ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "All players unignored\n";
			}
		}

	} elsif ($switch eq "00D3") {

	} elsif ($switch eq "00D6") {
		$currentChatRoom = "new";
		%{$chatRooms{'new'}} = %createdChatRoom;
		binAdd(\@chatRoomsID, "new");
		binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
		print "Chat Room Created ($chatRooms{$currentChatRoom}{'title'})\n";

	} elsif ($switch eq "00D7") {
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
		$msg = substr($msg, 0, 17).$newmsg;
		$ID = substr($msg,8,4);
		if (!%{$chatRooms{$ID}}) {
			binAdd(\@chatRoomsID, $ID);
		}
		$chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
		$chatRooms{$ID}{'ownerID'} = substr($msg,4,4);
		$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
		$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
		$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
		
	} elsif ($switch eq "00D8") {
		$ID = substr($msg,2,4);
		binRemove(\@chatRoomsID, $ID);
		undef %{$chatRooms{$ID}};

	} elsif ($switch eq "00DA") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 1) {
			print "Can't join Chat Room - Incorrect Password\n";
		} elsif ($type == 2) {
			print "Can't join Chat Room - You're banned\n";
		}

	} elsif ($switch eq "00DB") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg,4,4);
		$currentChatRoom = $ID;
		$chatRooms{$currentChatRoom}{'num_users'} = 0;
		for ($i = 8; $i < $msg_size; $i+=28) {
			$type = unpack("C1",substr($msg,$i,1));
			($chatUser) = substr($msg,$i + 4,24) =~ /([\s\S]*?)\000/;
			if ($chatRooms{$currentChatRoom}{'users'}{$chatUser} eq "") {
				binAdd(\@currentChatRoomUsers, $chatUser);
				if ($type == 0) {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
				} else {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
				}
				$chatRooms{$currentChatRoom}{'num_users'}++;
			}
		}
		print qq~You have joined the Chat Room "$chatRooms{$currentChatRoom}{'title'}"\n~;

	} elsif ($switch eq "00DC") {
		if ($currentChatRoom ne "") {
			$num_users = unpack("S1", substr($msg,2,2));
			($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
			binAdd(\@currentChatRoomUsers, $joinedUser);
			$chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
			$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
			print "$joinedUser has joined the Chat Room\n";
		}
	
	} elsif ($switch eq "00DD") {
		$num_users = unpack("S1", substr($msg,2,2));
		($leaveUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
		$chatRooms{$currentChatRoom}{'users'}{$leaveUser} = "";
		binRemove(\@currentChatRoomUsers, $leaveUser);
		$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
		if ($leaveUser eq $chars[$config{'char'}]{'name'}) {
			binRemove(\@chatRoomsID, $currentChatRoom);
			undef %{$chatRooms{$currentChatRoom}};
			undef @currentChatRoomUsers;
			$currentChatRoom = "";
			print "You left the Chat Room\n";
		} else {
			print "$leaveUser has left the Chat Room\n";
		}

	} elsif ($switch eq "00DF") {
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
		$msg = substr($msg, 0, 17).$newmsg;
		$ID = substr($msg,8,4);
		$ownerID = substr($msg,4,4);
		if ($ownerID eq $accountID) {
			$chatRooms{'new'}{'title'} = substr($msg,17,$msg_size - 17);
			$chatRooms{'new'}{'ownerID'} = $ownerID;
			$chatRooms{'new'}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{'new'}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{'new'}{'num_users'} = unpack("S1",substr($msg,14,2));
		} else {
			$chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
			$chatRooms{$ID}{'ownerID'} = $ownerID;
			$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
		}
		print "Chat Room Properties Modified\n";
	} elsif ($switch eq "00E1") {
		$type = unpack("C1",substr($msg, 2, 1));
		($chatUser) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if ($type == 0) {
			if ($chatUser eq $chars[$config{'char'}]{'name'}) {
				$chatRooms{$currentChatRoom}{'ownerID'} = $accountID;
			} else {
				$key = findKeyString(\%players, "name", $chatUser);
				$chatRooms{$currentChatRoom}{'ownerID'} = $key;
			}
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
		} else {
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
		}

	} elsif ($switch eq "00E4") {

	} elsif ($switch eq "00E5") {
		($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$incomingDeal{'name'} = $dealUser;
		$timeout{'ai_dealAutoCancel'}{'time'} = time;
		print "$dealUser Requests a Deal\n";

	} elsif ($switch eq "00E7") {
		$type = unpack("C1", substr($msg, 2, 1));
		
		if ($type == 3) {
			if (%incomingDeal) {
				$currentDeal{'name'} = $incomingDeal{'name'};
			} else {
				$currentDeal{'ID'} = $outgoingDeal{'ID'};
				$currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
			} 
			print "Engaged Deal with $currentDeal{'name'}\n";
		}
		undef %outgoingDeal;
		undef %incomingDeal;

	} elsif ($switch eq "00E9") {
		$amount = unpack("L*", substr($msg, 2,4));
		$ID = unpack("S*", substr($msg, 6,2));
		if ($ID > 0) {
			$currentDeal{'other'}{$ID}{'amount'} += $amount;
			$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
			$currentDeal{'other'}{$ID}{'name'} = $display;
			print "$currentDeal{'name'} added Item to Deal: $currentDeal{'other'}{$ID}{'name'} x $amount\n";
		} elsif ($amount > 0) {
			$currentDeal{'other_zenny'} += $amount;
			print "$currentDeal{'name'} added $amount z to Deal\n";
		}

	} elsif ($switch eq "00EA") {
		$index = unpack("S1", substr($msg, 2, 2));
		undef $invIndex;
		if ($index > 0) {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
			print "You added Item to Deal: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $currentDeal{'lastItemAmount'}\n";
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		} elsif ($currentDeal{'lastItemAmount'} > 0) {
			$chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
		}

	} elsif ($switch eq "00EC") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			$currentDeal{'other_finalize'} = 1;
			print "$currentDeal{'name'} finalized the Deal\n";
		} else {
			$currentDeal{'you_finalize'} = 1;
			print "You finalized the Deal\n";
		}

	} elsif ($switch eq "00EE") {
		undef %incomingDeal;
		undef %outgoingDeal;
		undef %currentDeal;
		print "Deal Cancelled\n";

	} elsif ($switch eq "00F0") {
		print "Deal Complete\n";
		undef %currentDeal;

	} elsif ($switch eq "00F2") {
		$storage{'items'} = unpack("S1", substr($msg, 2, 2));
		$storage{'items_max'} = unpack("S1", substr($msg, 4, 2));

	} elsif ($switch eq "00F4") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		if (%{$storage{$ID}}) {
			$storage{$ID}{'amount'} += $amount;
		} else {
			binAdd(\@storageID, $ID);
			$storage{$ID}{'index'} = $index;
			$storage{$ID}{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{$ID}{'name'} = $display;
			$storage{$ID}{'binID'} = binFind(\@storageID, $ID);
		}
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			$storage{$ID}{'refined'} = unpack("C1", substr($msg, 10, 1));
			if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
				$storage{$ID}{'elements'} = unpack("C1", substr($msg, 13, 1));
				$storage{$ID}{'star'}      = unpack("C1", substr($msg, 14, 1));
			} else {
				$storage{$ID}{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
				$storage{$ID}{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
				$storage{$ID}{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
				$storage{$ID}{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
			}
			modifingName(\%{$storage{$ID}});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
		$CONSOLE->Attr($FG_LIGHTGREEN|$BG_BLACK) if ($config{'colorMode'});
		print "Storage Item Added: $storage{$ID}{'name'} ($storage{$ID}{'binID'}) x $amount\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	} elsif ($switch eq "00F6") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = findKey(\%storage, "index", $index);
		$storage{$ID}{'amount'} -= $amount;
		print "Storage Item Removed: $storage{$ID}{'name'} ($storage{$ID}{'binID'}) x $amount\n";
		if ($storage{$ID}{'amount'} <= 0) {
			undef %{$storage{$ID}};
			binRemove(\@storageID, $ID);
		}

	} elsif ($switch eq "00F8") {
		print "Storage Closed\n";
#mod Start
#asimov Storage Log
		open  STCHAT, "> logs\/$config{'username'}_Storage.txt";
		print STCHAT "----------Storage ". getFormattedDate(int(time)) ."-----------\n";
		print STCHAT "#  Name\n";
		for ($i=0; $i < @storageID;$i++) {
			next if ($storageID[$i] eq "");
			print STCHAT "$i  $storage{$storageID[$i]}{'name'} x $storage{$storageID[$i]}{'amount'}\n";
		}
		print STCHAT "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
		print STCHAT "-------------------------------\n";
		close STCHAT;
#mod Stop
	} elsif ($switch eq "00FA") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			print "Can't organize party - party name exists\n";
		} 

	} elsif ($switch eq "00FB") {
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($chars[$config{'char'}]{'party'}{'name'}) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		for ($i = 28; $i < $msg_size;$i+=46) {
			$ID = substr($msg, $i, 4);
			$num = unpack("C1",substr($msg, $i + 44, 1));
			if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
				binAdd(\@partyUsersID, $ID);
			}
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 1 if ($num == 0);
		}
		sendPartyShareEXP(\$remote_socket, 1) if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}});

	} elsif ($switch eq "00FD") {
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$type = unpack("C1", substr($msg, 26, 1));
		if ($type == 0) {
			print "Join request failed: $name is already in a party\n";
		} elsif ($type == 1) {
			print "Join request failed: $name denied request\n";
		} elsif ($type == 2) {
			print "$name accepted your request\n";
		}

	} elsif ($switch eq "00FE") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to join party '$name'\n";
		$incomingParty{'ID'} = $ID;
		$timeout{'ai_partyAutoDeny'}{'time'} = time;

	} elsif ($switch eq "0100") {

	} elsif ($switch eq "0101") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 0) {
			print "Party EXP set to Individual Take\n";
		} elsif ($type == 1) {
			print "Party EXP set to Even Share\n";
		} else {
			print "Error setting party option\n";
		}
		
	} elsif ($switch eq "0104") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,10, 2));
		$y = unpack("S1", substr($msg,12, 2));
		$type = unpack("C1",substr($msg, 14, 1));
		($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
		($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
		($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;
		if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
			binAdd(\@partyUsersID, $ID);
			if ($ID eq $accountID) {
				print "You joined party '$name'\n";
			} else {
				print "$partyUser joined your party '$name'\n";
			}
		}
		if ($type == 0) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		} elsif ($type == 1) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
		}
		$chars[$config{'char'}]{'party'}{'name'} = $name;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = $map;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} = $partyUser;
		
	} elsif ($switch eq "0105") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
		binRemove(\@partyUsersID, $ID);
		if ($ID eq $accountID) {
			print "You left the party\n";
			undef %{$chars[$config{'char'}]{'party'}};
			$chars[$config{'char'}]{'party'} = "";
			undef @partyUsersID;
		} else {
			print "$name left the party\n";
		}

	} elsif ($switch eq "0106") {
		$ID = substr($msg, 2, 4);
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = unpack("S1", substr($msg, 6, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));

	} elsif ($switch eq "0107") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,6, 2));
		$y = unpack("S1", substr($msg,8, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		print "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);

	} elsif ($switch eq "0108") {
		$type =  unpack("S1",substr($msg, 2, 2));
		$index = unpack("S1",substr($msg, 4, 2));
		$enchant = unpack("S1",substr($msg, 6, 2));
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = $enchant;
		print "Your Weapon Element changed to : $elements_lut{$enchant}\n";
	} elsif ($switch eq "0109") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$chat = substr($msg, 8, $msg_size - 8);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("p", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "p";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
		print "%$chat\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	# wooooo MVP info
	} elsif ($switch eq "010A") {
		$ID = unpack("S1", substr($msg, 2, 2)); 
		print "You get MVP Item : ".$items_lut{$ID}."\n"; 
		chatLog("c","You get MVP Item : ".$items_lut{$ID}."\n");

	} elsif ($switch eq "010B") { 
		$val = unpack("S1",substr($msg, 2, 2)); 
		print "You're MVP!!! Special exp gained: $val\n";
		chatLog("c","You're MVP!!! Special exp gained: $val\n");

	} elsif ($switch eq "010C") {
		$ID = substr($msg, 2, 4); 
		$display = "Unknown"; 
		if (%{$players{$ID}}) { 
			$display = "Player ". $players{$ID}{'name'} . "(" . $players{$ID}{'binID'} . ") "; 
		} elsif ($ID eq $accountID) { 
			$display = "Your"; 
		} 
		print "$display become MVP!\n"; 
		chatLog("c", $display . " become MVP!\n"); 
	###

	} elsif ($switch eq "010E") {
		$ID = unpack("S1",substr($msg, 2, 2));
		$lv = unpack("S1",substr($msg, 4, 2));
		$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ID})}}{'lv'} = $lv;
		print "Skill $skillsID_lut{$ID}: $lv\n" if $config{'debug'};

	} elsif ($switch eq "010F") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @skillsID;
		for($i = 4;$i < $msg_size;$i+=37) {
			$ID = unpack("S1", substr($msg, $i, 2));
			($name) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
			if (!$name) {
				$name = $skills_rlut{lc($skillsID_lut{$ID})};
			}
			$chars[$config{'char'}]{'skills'}{$name}{'ID'} = $ID;
			if (!$chars[$config{'char'}]{'skills'}{$name}{'lv'}) {
				$chars[$config{'char'}]{'skills'}{$name}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
			}
			$skillsID_lut{$ID} = $skills_lut{$name};
			binAdd(\@skillsID, $name);
		}

	} elsif ($switch eq "0110") {
		#Parse this: warp portal

	} elsif ($switch eq "0111") {

	} elsif ($switch eq "0114" || $switch eq "01DE") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		$damage = unpack("S1",substr($msg, 24, 2));
		$level = ($switch eq "0114") ? unpack("S1",substr($msg, 26, 2)) : unpack("S1",substr($msg, 28, 2));
		undef $sourceDisplay;
		undef $targetDisplay;
		undef $extra;
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
			
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		} else {
			$sourceDisplay = "Unknown uses";
		}

		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} else {
			$targetDisplay = "unknown";
		}
		
		if ($damage != 35536) { 
        	if ($level_real ne "") { 
            	$level = $level_real; 
            } 
            print "$sourceDisplay $skillsID_lut{$skillID} (lvl $level) on $targetDisplay$extra - Dmg: $damage\n"; 
        } else { 
            $level_real = $level; 
            print "$sourceDisplay $skillsID_lut{$skillID} (lvl $level)\n"; 
       	} 

	} elsif ($switch eq "0115") {

	} elsif ($switch eq "0117") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$lv = unpack("S1",substr($msg, 8, 2));
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		
		undef $sourceDisplay;
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		} else {
			$sourceDisplay = "Unknown uses";
		}
		print "$sourceDisplay $skillsID_lut{$skillID} on location ($x, $y)\n";

	#cureAuto_poison - Chobit Andy 20030408 
	} elsif ($switch eq "0119") { 
		$ID = substr($msg, 2, 4);
		$type = unpack("S1", substr($msg, 8, 2));
		$frozen = unpack("S1", substr($msg, 6, 2)); 
		if ($ID eq $accountID) { 
			if ($type == 1) { 
				print "You have affected by poison\n";
				if ($config{'cureAuto_poison'}) {
					if ($chars[$config{'char'}]{'skills'}{'TF_DETOXIFY'}{'lv'}) {
						print "Auto-Cure Poison use Skill : Detoxify\n";
						ai_skillUse($chars[$config{'char'}]{'skills'}{'TF_DETOXIFY'}{'ID'}, 1, 0,0, $accountID);
					}else{
						undef $ai_v{'temp'}{'invIndex'}; 
						$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 511);
						$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 506) if ($ai_v{'temp'}{'invIndex'} ne "");
						$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 525) if ($ai_v{'temp'}{'invIndex'} ne "");
						if ($ai_v{'temp'}{'invIndex'} ne "") { 
							print "Auto-Cure Poison use item : $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n";
							sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID); 
						}else{
							print "No item to Auto-Cure Poison\n";
						}
					}
				}
			}
#mod Start
		}elsif (%{$players{$ID}}){
			if ($type ==1) {
				print "$players{$ID}{'name'} has affected by poison\n" if ($config{'debug'});
			}elsif ($frozen >=1){
				print "$players{$ID}{'name'} has affected froze or trap\n" if ($config{'debug'});
				$players{$ID}{'frozen'} = $frozen;
			}
		}elsif (%{$monsters{$ID}}){
			if ($type ==1) {
				print "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) has affected by poison\n" if ($config{'debug'});
			}elsif ($frozen >=1){
				print "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) has affected froze or trap\n" if ($config{'debug'});
				$monsters{$ID}{'frozen'} = $frozen;
			}
#mod Stop
		}

	} elsif ($switch eq "011A") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$targetID = substr($msg, 6, 4);
		$sourceID = substr($msg, 10, 4);
		$amount = unpack("S1",substr($msg, 4, 2));
		undef $sourceDisplay;
		undef $targetDisplay;
		undef $extra;
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		} else {
			$sourceDisplay = "Unknown uses";
		}
		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} else {
			$targetDisplay = "unknown";
		}
		if ($skillID == 28) {
			$extra = ": $amount hp gained";
		} else {
			$extra = ": Lv $amount";
		}
		print "$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay$extra\n";
#mod Start
# Detect Heal
		if ($skillID==28 || $skillID==29 || $skillID == 34){
			if ($targetDisplay eq "$monsters{$ai_seq_args[0]{'ID'}}{'name'} ($monsters{$ai_seq_args[0]{'ID'}}{'binID'})"
				&& $config{'AntiSkillonMonster'} && %{$players{$sourceID}}){
				$CONSOLE->Attr($FG_RED|$BG_BLACK) if ($config{'colorMode'});
				print "$players{$sourceID}{'name'} use $skillsID_lut{$skillID} on Your Attacked Monster \n";
				chatLog("D","** $players{$sourceID}{'name'} use $skillsID_lut{$skillID} on Your Attacked Monster \n");
				updatepplControl("$def_config/ppl_control.txt",$players{$sourceID}{'name'},unpack("L1",$sourceID)) if (!%{$ppl_control{$players{$sourceID}{'name'}}});
				if (!$ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'}) {
						if ($ai_seq[0] eq "attack") {
							shift @ai_seq;
							shift @ai_seq_args;
							ai_setSuspend(0);
							sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
						}
						$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
						$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
						$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
						$ai_cmdQue[$ai_cmdQue]{'msg'} = "/AntiSkill$skillID";
						$ai_cmdQue[$ai_cmdQue]{'time'} = time;
						$ai_cmdQue++;
				}else{
						parseReload("ppl");
						if (!$ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'} && $config{'avoidGM'}<3 && $config{'avoidGM'}>0) {
							useTeleport($config{'AvoidGM'});
						}
				}
				$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
			}elsif ($targetDisplay eq "you" && $config{'AutoThanks'} && %{$players{$sourceID}}){
				if (!$ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'}) {
					sendAttackStop(\$remote_socket) if ($ai_seq[0] eq "attack" && $config{'attackUseWeapon'});
					shift @ai_seq;
					shift @ai_seq_args;
					$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
					$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
					$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
					$ai_cmdQue[$ai_cmdQue]{'msg'} = "/Thanks";
					$ai_cmdQue[$ai_cmdQue]{'time'} = time;
					$ai_cmdQue++;
				}
			}
		}
#mod Stop
	} elsif ($switch eq "011C") {

	} elsif ($switch eq "011E") {
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Memo Failed\n";
		} else {
			print "Memo Succeeded\n";
		}

	} elsif ($switch eq "011F") {
		#area effect spell
		$ID = substr($msg, 2, 4);
		$SourceID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$spells{$ID}{'sourceID'} = $SourceID;
		$spells{$ID}{'pos'}{'x'} = $x;
		$spells{$ID}{'pos'}{'y'} = $y;
		$binID = binAdd(\@spellsID, $ID);
		$spells{$ID}{'binID'} = $binID;
	} elsif ($switch eq "0120") {
		#The area effect spell with ID dissappears
		$ID = substr($msg, 2, 4);
		undef %{$spells{$ID}};
		binRemove(\@spellsID, $ID);

#Cart Parses - chobit andy 20030102
	} elsif ($switch eq "0121") {
		$cart{'items'} = unpack("S1", substr($msg, 2, 2));
		$cart{'items_max'} = unpack("S1", substr($msg, 4, 2));
		$cart{'weight'} = int(unpack("L1", substr($msg, 6, 4)) / 10);
		$cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);

	} elsif ($switch eq "0122") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$type = unpack("C1",substr($msg, $i+4, 1));
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$oldID = $ID;
			$ID += 30000;
			while (%{$cart{'inventory'}{$ID}}) {
				$ID += 1;
			}
			binAdd(\@cartID, $ID);
			$cart{'inventory'}{$ID}{'index'} = $index;
			$cart{'inventory'}{$ID}{'nameID'} = $ID;
			$cart{'inventory'}{$ID}{'amount'} = 1;
			$cart{'inventory'}{$ID}{'name'} = $display;
			$cart{'inventory'}{$ID}{'binID'} = binFind(\@cartID, $ID);
			$cart{'inventory'}{$ID}{'identified'} = unpack("C1", substr($msg, $i+5, 1));
			$cart{'inventory'}{$ID}{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$cart{'inventory'}{$ID}{'oldID'} = $oldID;
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			$cart{'inventory'}{$ID}{'refined'} = unpack("C1", substr($msg, $i+11, 1));
			if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
				$cart{'inventory'}{$ID}{'elements'} = unpack("C1", substr($msg, $i+14, 1));
				$cart{'inventory'}{$ID}{'star'}      = unpack("C1", substr($msg, $i+15, 1))/ 0x05;
			} else {
				$cart{'inventory'}{$ID}{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
				$cart{'inventory'}{$ID}{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
				$cart{'inventory'}{$ID}{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
				$cart{'inventory'}{$ID}{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
			}
			modifingName(\%{$cart{'inventory'}{$ID}});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
			print "Non-Stackable Cart Item: $cart{'inventory'}{$ID}{'name'} ($cart{'inventory'}{$ID}{'binID'}) x 1\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0123") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=10) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$amount = unpack("S1", substr($msg, $i+6, 2));
			if (%{$cart{'inventory'}{$ID}}) {
				$cart{'inventory'}{$ID}{'amount'} += $amount;
			} else {
				binAdd(\@cartID, $ID);
				$cart{'inventory'}{$ID}{'index'} = $index;
				$cart{'inventory'}{$ID}{'amount'} = $amount;
				$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
				$cart{'inventory'}{$ID}{'name'} = $display;
				$cart{'inventory'}{$ID}{'binID'} = binFind(\@cartID, $ID);
			}
			print "Cart Item: $cart{'inventory'}{$ID}{'name'} ($cart{'inventory'}{$ID}{'binID'}) x $amount\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0124") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
#mod Start
#Solos Fix Cart
		if ($ID >= 9000) {
			$oldID = $ID;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$ID += 30000;
			while (%{$cart{'inventory'}{$ID}}) {
				$ID += 1;
			}
			binAdd(\@cartID, $ID);
			$cart{'inventory'}{$ID}{'index'} = $index;
			$cart{'inventory'}{$ID}{'amount'} = $amount;
			$cart{'inventory'}{$ID}{'name'} = $display;
			$cart{'inventory'}{$ID}{'binID'} = binFind(\@cartID, $ID);
			$cart{'inventory'}{$ID}{'oldID'} = $oldID;
		}elsif (%{$cart{'inventory'}{$ID}}) {
#mod Stop
			$cart{'inventory'}{$ID}{'amount'} += $amount;
		} else {
			binAdd(\@cartID, $ID);
			$cart{'inventory'}{$ID}{'index'} = $index;
			$cart{'inventory'}{$ID}{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$cart{'inventory'}{$ID}{'name'} = $display;
			$cart{'inventory'}{$ID}{'binID'} = binFind(\@cartID, $ID);
		}
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			#<index>.w <amount>.l <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
			$cart{'inventory'}{$ID}{'identify'} = unpack("C1", substr($msg, 10, 1));
			$cart{'inventory'}{$ID}{'refined'} = unpack("C1", substr($msg, 12, 1));
			if (unpack("S1", substr($msg, 13, 2)) == 0x00FF) {
				$cart{'inventory'}{$ID}{'elements'} = unpack("C1", substr($msg, 15, 1));
				$cart{'inventory'}{$ID}{'star'}      = unpack("C1", substr($msg, 16, 1))/ 0x05;
			} else {
				$cart{'inventory'}{$ID}{'card'}[0]   = unpack("S1", substr($msg, 13, 2));
				$cart{'inventory'}{$ID}{'card'}[1]   = unpack("S1", substr($msg, 15, 2));
				$cart{'inventory'}{$ID}{'card'}[2]   = unpack("S1", substr($msg, 17, 2));
				$cart{'inventory'}{$ID}{'card'}[3]   = unpack("S1", substr($msg, 19, 2));
			}
			modifingName(\%{$cart{'inventory'}{$ID}});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
		print "Cart Item Added: $cart{'inventory'}{$ID}{'name'} ($cart{'inventory'}{$ID}{'binID'}) x $amount\n";

	} elsif ($switch eq "0125") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = findKey(\%{$cart{'inventory'}}, "index", $index);
		$cart{'inventory'}{$ID}{'amount'} -= $amount;
		print "Cart Item Removed: $cart{'inventory'}{$ID}{'name'} ($cart{'inventory'}{$ID}{'binID'}) x $amount\n";
		if ($cart{'inventory'}{$ID}{'amount'} <= 0) {
			undef %{$cart{'inventory'}{$ID}};
			binRemove(\@cartID, $ID);
		}

	} elsif ($switch eq "012C") {
		$index = unpack("S1", substr($msg, 3, 2));
		$amount = unpack("L1", substr($msg, 7, 2));
		$ID = unpack("S1", substr($msg, 9, 2));
		if ($items_lut{$ID} ne "") {
			print "Can't Add Cart Item: $items_lut{$ID}\n";
		}

#mod Start
#Solos Vender
	} elsif ($switch eq "012D" ){
		#used the shop skill.
		$number = unpack("S1",substr($msg, 2, 2));
		print "You can sell $number items!\n";

	} elsif ($switch eq "0131") {
		$ID = substr($msg,2,4);
		if (!%{$venderLists{$ID}}) {
			binAdd(\@venderListsID, $ID);
		}
		($venderLists{$ID}{'title'}) = substr($msg,6,36) =~ /(.*?)\000/;

	} elsif ($switch eq "0132") {
		$ID = substr($msg,2,4);
		binRemove(\@venderListsID, $ID);
		undef %{$venderLists{$ID}};

	} elsif ($switch eq "0133") {
			undef @venderItemList;
			undef $venderID;
			$venderID = substr($msg,4,4);
			$venderItemList = 0;
			$~ = "VSTORELIST";
			print "----------Vender Store List-----------\n";
			print "#  Name                          Type       Amount     Price\n";
			for ($i = 8; $i < $msg_size; $i+=22) {
				$index = unpack("S1", substr($msg, $i + 6, 2));
				$ID = unpack("S1", substr($msg, $i + 9, 2));
				$venderItemList[$index]{'nameID'} = $ID;
				$display = ($items_lut{$ID} ne "") 
					? $items_lut{$ID}
					: "Unknown ".$ID;
#mod Start
# parse Card & Elements
				#------------------------------------------------------------------------------------------------------------
				$venderItemList[$index]{'name'} = $display;
				$venderItemList[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
				$venderItemList[$index]{'amount'} = unpack("S1", substr($msg, $i + 4, 2));
				$venderItemList[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
				$venderItemList[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
				$venderItemList[$index]{'refined'} = unpack("C1", substr($msg, $i + 13, 1));
				if (unpack("S1", substr($msg,$i+14, 2)) == 0x00FF) {
					$venderItemList[$index]{'elements'} = unpack("C1", substr($msg,$i+16, 1));
					$venderItemList[$index]{'star'}      = unpack("C1", substr($msg,$i+17, 1)) / 0x05;
				}else{
					$venderItemList[$index]{'card'}[0] = unpack("S1", substr($msg, $i + 14, 2));
					$venderItemList[$index]{'card'}[1] = unpack("S1", substr($msg, $i + 16, 2));
					$venderItemList[$index]{'card'}[2] = unpack("S1", substr($msg, $i + 18, 2));
					$venderItemList[$index]{'card'}[3] = unpack("S1", substr($msg, $i + 20, 2));
				}
				modifingName(\%{$venderItemList[$index]});
				#------------------------------------------------------------------------------------------------------------
#mod Stop
				$venderItemList++;
				print "Item added to Vender Store: $items{$ID}{'name'} - $price z\n" if ($config{'debug'} >= 2);

				format VSTORELIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @>>>>> @>>>>>>>z
$index $venderItemList[$index]{'name'} $itemTypes_lut{$venderItemList[$index]{'type'}} $venderItemList[$index]{'amount'} $venderItemList[$index]{'price'}
.
				write;
			}
			print "--------------------------------------\n";
#mod Stop
	} elsif ($switch eq "0135") {

	} elsif ($switch eq "0136") {
		undef %shopItem;
		undef @articles;
		$articles = 0; 
		$~ = "ARTICLESLIST"; 
		print "---------- $shop{'shop_title'} -------------\n"; 
		print "#  Name                          Type     Amount      Price\n";
		for ($i = 8; $i < $msg_size; $i+=22) { 
			$index = unpack("S1", substr($msg, $i + 4, 2)); 
			$articles[$index]{'price'} = unpack("L1", substr($msg, $i, 4)); 
			$articles[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2)); 
			$articles[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
			$ID = unpack("S1", substr($msg, $i + 9, 2)); 
			$articles[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1)); 
			$articles[$index]{'nameID'} = $ID; 
			$display = ($items_lut{$ID} ne "") 
				? $items_lut{$ID} 
				: "Unknown ".$ID; 
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			#<value>.l <index>.w <amount>.w <type>.B <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
			$articles[$index]{'name'} = $display;
			$articles[$index]{'refined'} = unpack("C1", substr($msg, $i + 13, 1));
			if (unpack("S1", substr($msg,$i+14, 2)) == 0x00FF) {
				$articles[$index]{'elements'} = unpack("C1", substr($msg,$i+16, 1));
				$articles[$index]{'star'}      = unpack("C1", substr($msg,$i+17, 1)) / 0x05;
			}else{
				$articles[$index]{'card'}[0] = unpack("S1", substr($msg, $i + 14, 2)); 
				$articles[$index]{'card'}[1] = unpack("S1", substr($msg, $i + 16, 2)); 
				$articles[$index]{'card'}[2] = unpack("S1", substr($msg, $i + 18, 2)); 
				$articles[$index]{'card'}[3] = unpack("S1", substr($msg, $i + 20, 2)); 
			}
			modifingName(\%{$articles[$index]});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
			$articles++; 
			format ARTICLESLIST = 
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>>> @>>>>>>>>>z
$index $articles[$index]{'name'} $itemTypes_lut{$articles[$index]{'type'}} $articles[$index]{'amount'} $articles[$index]{'price'} 
. 
write; 
		} 
		print "-------------------------","-"x length($shop{'shop_title'}),"\n"; 

	} elsif ($switch eq "0137") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$price = $amount * $articles[$index]{'price'};
		$articles[$index]{'sold'} += $amount;
		$shop{'earned'} += $amount * $articles[$index]{'price'};
		$articles[$index]{'amount'} -= $amount;
		print "sold item : $articles[$index]{'name'} x $amount - $price z\n";
		chatLog("shop","sold item : $articles[$index]{'name'} x $amount - $price z\n");
		if ($articles[$index]{'amount'} < 1) {
			if (!--$articles){
				print "all sold out.^^\n";
				closeShop(\$remote_socket);
			}
		}
	} elsif ($switch eq "0139") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 14, 1));
		$coords1{'x'} = unpack("S1",substr($msg, 6, 2));
		$coords1{'y'} = unpack("S1",substr($msg, 8, 2));
		$coords2{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords2{'y'} = unpack("S1",substr($msg, 12, 2));
		%{$monsters{$ID}{'pos_attack_info'}} = %coords1;
		%{$chars[$config{'char'}]{'pos'}} = %coords2;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords2;
		print "Recieved attack location - $monsters{$ID}{'pos_attack_info'}{'x'}, $monsters{$ID}{'pos_attack_info'}{'y'} - ".getHex($ID)."\n" if ($config{'debug'} >= 2);

	} elsif ($switch eq "013A") {
		$type = unpack("S1",substr($msg, 2, 2));
#mod Start
#Hambo Arrow Equip
	} elsif ($switch eq "013B") {
		$type = unpack("S1",substr($msg, 2, 2)); 
		if ($type == 0) { 
			print "Please equip arrow first\n"; 
		} elsif ($type == 3) { 
			print "Arrow equipped\n" if $config{'debug'}; 
		} 

	} elsif ($switch eq "013C") {
		$index = unpack("S1", substr($msg, 2, 2)); 
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index); 
		if ($invIndex ne "") { 
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}; 
			print "Arrow equipped: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} 
#mod Stop
	} elsif ($switch eq "013D") {
		$type = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		if ($type == 5) {
			$chars[$config{'char'}]{'hp'} += $amount;
			$chars[$config{'char'}]{'hp'} = $chars[$config{'char'}]{'hp_max'} if ($chars[$config{'char'}]{'hp'} > $chars[$config{'char'}]{'hp_max'});
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} += $amount;
			$chars[$config{'char'}]{'sp'} = $chars[$config{'char'}]{'sp_max'} if ($chars[$config{'char'}]{'sp'} > $chars[$config{'char'}]{'sp_max'});
		}

	} elsif ($switch eq "013E") {
		$sourceID = substr($msg, 2, 4);
		$targetID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$skillID = unpack("S1",substr($msg, 14, 2));
		undef $sourceDisplay;
		undef $targetDisplay;
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) is casting";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) is casting";
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You are casting";
			$chars[$config{'char'}]{'time_cast'} = time;
		} else {
			$sourceDisplay = "Unknown is casting";
		}

			
		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} elsif ($x != 0 || $y != 0) {
			$targetDisplay = "location ($x, $y)";
		} else {
			$targetDisplay = "unknown";
		}
		print "$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay\n";
#mod Start
# Detect Warp
		if ($skillID == 27&&($chars[$config{'char'}]{'pos_to'}{'x'}==$x)
			&&($chars[$config{'char'}]{'pos_to'}{'y'}==$y)&&$currentChatRoom eq ""&& !$ai_v{'temp'}{'shopOpen'}){
			$CONSOLE->Attr($FG_RED|$BG_BLACK) if ($config{'colorMode'});
			print "$players{$sourceID}{'name'} Trying to Warp You \n";
			chatLog("D","** $players{$sourceID}{'name'} Trying to Warp You \n");
			updatepplControl("$def_config/ppl_control.txt",$players{$sourceID}{'name'},unpack("L1",$sourceID)) if (!%{$ppl_control{$players{$sourceID}{'name'}}});
			if ($config{'AntiWarp'} == 1) {
				if (!$ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'}) {
					if ($ai_seq[0] eq "attack") {
						shift @ai_seq;
						shift @ai_seq_args;
						ai_setSuspend(0);
						sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
					}
					$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
					$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
					$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
					$ai_cmdQue[$ai_cmdQue]{'msg'} = "/Warp";
					$ai_cmdQue[$ai_cmdQue]{'time'} = time;
					$ai_cmdQue++;
				}
				do { 
					$ai_v{'temp'}{'randX'} = $x + ((int(rand(3))-1)*(int(rand($config{'Avoid_WalkDistance'}))+1));
					$ai_v{'temp'}{'randY'} = $y + ((int(rand(3))-1)*(int(rand($config{'Avoid_WalkDistance'}))+1));
				} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]
					&& $ai_v{'temp'}{'randX'}==$chars[$config{'char'}]{'pos_to'}{'x'}
					&& $ai_v{'temp'}{'randY'}==$chars[$config{'char'}]{'pos_to'}{'y'}
				);
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
			}elsif ($config{'AntiWarp'} == 2) { useTeleport(2); }
			$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		}elsif ($skillID==12 && $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}==$x && $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}==$y) {
			$CONSOLE->Attr($FG_RED|$BG_BLACK) if ($config{'colorMode'});
			print "$players{$sourceID}{'name'} Trying to use Safety Wall on Your Attack Monster \n";
			chatLog("D","** $players{$sourceID}{'name'} Trying to use Safety Wall on Your Attack Monster \n");
			updatepplControl("$def_config/ppl_control.txt",$players{$sourceID}{'name'},unpack("L1",$sourceID)) if (!%{$ppl_control{$players{$sourceID}{'name'}}});
			if ($config{'AntiSkillonMonster'}) {
				if (!$ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'}) {
					if ($ai_seq[0] eq "attack") {
						shift @ai_seq;
						shift @ai_seq_args;
						sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
					}
					$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
					$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
					$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
					$ai_cmdQue[$ai_cmdQue]{'msg'} = "/AntiSkill12";
					$ai_cmdQue[$ai_cmdQue]{'time'} = time;
					$ai_cmdQue++;
				}
				do { 
					$ai_v{'temp'}{'randX'} = $x + ((int(rand(3))-1)*(int(rand($config{'Avoid_WalkDistance'}))+1));
					$ai_v{'temp'}{'randY'} = $y + ((int(rand(3))-1)*(int(rand($config{'Avoid_WalkDistance'}))+1));
				} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]
					&& $ai_v{'temp'}{'randX'}==$chars[$config{'char'}]{'pos_to'}{'x'}
					&& $ai_v{'temp'}{'randY'}==$chars[$config{'char'}]{'pos_to'}{'y'}
				);
			}
			$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		}
#mod Stop
	} elsif ($switch eq "0141") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("S1",substr($msg, 6, 2));
		$val2 = unpack("S1",substr($msg, 10, 2));
		if ($type == 13) {
			$chars[$config{'char'}]{'str'} = $val;
			$chars[$config{'char'}]{'str_bonus'} = $val2;
			print "Strength: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 14) {
			$chars[$config{'char'}]{'agi'} = $val;
			$chars[$config{'char'}]{'agi_bonus'} = $val2;
			print "Agility: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 15) {
			$chars[$config{'char'}]{'vit'} = $val;
			$chars[$config{'char'}]{'vit_bonus'} = $val2;
			print "Vitality: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 16) {
			$chars[$config{'char'}]{'int'} = $val;
			$chars[$config{'char'}]{'int_bonus'} = $val2;
			print "Intelligence: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 17) {
			$chars[$config{'char'}]{'dex'} = $val;
			$chars[$config{'char'}]{'dex_bonus'} = $val2;
			print "Dexterity: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 18) {
			$chars[$config{'char'}]{'luk'} = $val;
			$chars[$config{'char'}]{'luk_bonus'} = $val2;
			print "Luck: $val + $val2\n" if $config{'debug'};
		}

	} elsif ($switch eq "0145") {

	} elsif ($switch eq "0147") { 
		$skillID = unpack("S*",substr($msg, 2, 2)); 
		$skillLv = unpack("S*",substr($msg, 8, 2));
		print "Now using $skillsID_lut{$skillID}, lv $skillLv\n"; 
		sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);

	} elsif ($switch eq "0154") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		my $c = 0;
		for($i = 4; $i < $msg_size; $i+=104){
			$guild{'member'}[$c]{'ID'}    = substr($msg, $i, 4);
			$guild{'member'}[$c]{'jobID'} = unpack("S1", substr($msg, $i + 14, 2));
			$guild{'member'}[$c]{'lvl'}   = unpack("S1", substr($msg, $i + 16, 2));
			$guild{'member'}[$c]{'contribution'} = unpack("L1", substr($msg, $i + 18, 4));
			$guild{'member'}[$c]{'online'} = unpack("S1", substr($msg, $i + 22, 2));
			$gtIndex = unpack("L1", substr($msg, $i + 26, 4));
			$guild{'member'}[$c]{'title'} = $guild{'title'}[$gtIndex];
			($guild{'member'}[$c]{'name'}) = substr($msg, $i + 80, 24) =~ /([\s\S]*?)\000/;
			$c++;
		}

	} elsif ($switch eq "0166") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		my $gtIndex;
		for($i = 4; $i < $msg_size; $i+=28) {
			$gtIndex = unpack("L1", substr($msg, $i, 4));
			($guild{'title'}[$gtIndex]) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
		}

	} elsif ($switch eq "016A") {
		# guild request for you
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to join Guild '$name'\n";
		$incomingGuild{'ID'} = $ID;
		$incomingGuild{'Type'} = 1;
		$timeout{'ai_guildAutoDeny'}{'time'} = time;

	} elsif ($switch eq "016C") {
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;

	} elsif ($switch eq "016D") { 
		$ID = substr($msg, 2, 4); 
		$TargetID =  substr($msg, 6, 4); 
		$type = unpack("L1", substr($msg, 10, 4)); 
		if ($type) { 
			$isOnline = "Log In"; 
		} else { 
			$isOnline = "Log Out"; 
		}
		sendNameRequest(\$remote_socket, $TargetID); 

	} elsif ($switch eq "016F") {
		($address) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;
		$CONSOLE->Attr($FG_YELLOW|$BG_BLACK) if ($config{'colorMode'});
		print	"---Guild Notice---\n"
			,"$address\n\n"
			,"$message\n"
			,"------------------\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	} elsif ($switch eq "0171") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /[\s\S]*?\000/;
		print "Incoming Request to Ally Guild '$name'\n";
		$incomingGuild{'ID'} = $ID;
		$incomingGuild{'Type'} = 2;
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
#Mod Stop

	} elsif ($switch eq "0177") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @identifyID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@identifyID, $invIndex);
		}
		print "Recieved Possible Identify List - type 'identify'\n";

	} elsif ($switch eq "0179") {
		$index = unpack("S*",substr($msg, 2, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
		print "Item Identified: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n";
		undef @identifyID;

	} elsif ($switch eq "017F") { 
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 4, $msg_size - 4); 
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("g", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "g"; 
		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID; 
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser; 
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg; 
		$ai_cmdQue[$ai_cmdQue]{'time'} = time; 
		$ai_cmdQue++;
		$CONSOLE->Attr($FG_YELLOW|$BG_BLACK) if ($config{'colorMode'});
		print "[Guild] $chat\n";
		$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});

	} elsif ($switch eq "0180") {

	} elsif ($switch eq "0183") {

	} elsif ($switch eq "0187") {

	} elsif ($switch eq "0188") {
		$type =  unpack("S1",substr($msg, 2, 2));
		$index = unpack("S1",substr($msg, 4, 2));
		$enchant = unpack("S1",substr($msg, 6, 2));
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = $enchant;
		print "Your Weapon Element changed to : $elements_lut{$enchant}\n";
	} elsif ($switch eq "018A") {

	} elsif ($switch eq "018E") {

	} elsif ($switch eq "0192") {

#Mod Start
#Parse Guildman Connect
	} elsif ($switch eq "0194") {
		$ID = substr($msg, 2, 4); 
		if ($ID ne $accountID) {
			($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			$CONSOLE->Attr($FG_YELLOW |$BG_BLACK) if ($config{'colorMode'});
			print "Guild Member : $name $isOnline\n";
			$CONSOLE->Attr($FG_GRAY) if ($config{'colorMode'});
		}
		sendGuildInfoRequest(\$remote_socket);
		sendGuildRequest(\$remote_socket, 0);
		sendGuildRequest(\$remote_socket, 1);
#Mod Stop
	} elsif ($switch eq "0195") {
		$ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
			print "Player Info: $players{$ID}{'name'} ($players{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
		}

	} elsif ($switch eq "0196") {
#mod Start
# Status Parser
		$type = unpack("S1",substr($msg, 2, 2));
		$ID = substr($msg, 4, 4);
		$flag = unpack("C1",substr($msg, 8, 1));
		if ($ID eq $accountID) {
			if ($flag==1) {
				if ($chars[$config{'char'}]{'skillST'}!~/$skillsST_lut{$type}/) {
					$chars[$config{'char'}]{'skillST'} .= "$skillsST_lut{$type} ";
				}
			}else{
				$chars[$config{'char'}]{'skillST'} =~s/$skillsST_lut{$type} //;
			}
		}
		dumpData(substr($msg, 0, 9)) if ($config{'debug'});
#mod Stop
	} elsif ($switch eq "019B") {
		$ID = substr($msg, 2, 4);
		$type = unpack("L1",substr($msg, 6, 4));
		if ($ID eq $accountID) {
			$name = "You"
		}elsif (%{$players{$ID}}) {
			$name = $players{$ID}{'name'};
		} else {
			$name = "Unknown";
		}
		if ($type == 0) {
			print "$name gained a level!\n";
		} elsif ($type == 1) {
			print "$name gained a job level!\n";
		}

	} elsif ($switch eq "01A2") {
		#pet
#mod Start
# Pet Info
		($chars[$config{'char'}]{'pet'}{'name'}) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/; 
		$chars[$config{'char'}]{'pet'}{'name_flag'} = unpack("C1",substr($msg, 26, 1)); 
		$chars[$config{'char'}]{'pet'}{'level'} = unpack("S1",substr($msg, 27, 2)); 
		$chars[$config{'char'}]{'pet'}{'hungry'} = unpack("S1",substr($msg, 29, 2)); 
		$chars[$config{'char'}]{'pet'}{'friendly'} = unpack("S1",substr($msg, 31, 2)); 
		$chars[$config{'char'}]{'pet'}{'accessory'} = unpack("S1",substr($msg, 33, 2)); 
		$chars[$config{'char'}]{'pet'}{'action'} = 0;

	} elsif ($switch eq "01A3") { 
		$success=unpack("C1",substr($msg, 2, 1)); 
		$ID=unpack("S1",substr($msg, 3, 2));
		if (!$success) {
			print "You can't give a food($items_lut{$ID}), auto return to egg\n";
			sendPetCommand(\$remote_socket, 3);
			undef %{$chars[$config{'char'}]{'pet'}};
		}

	} elsif ($switch eq "01A4") {
		#pet spawn
		$type = unpack("C1",substr($msg, 2, 1));
		$ID = substr($msg, 3, 4);
		$val = unpack("L",substr($msg, 7, 4)); 
		
		if (($type < 3 || $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) && %{$pets{$ID}}) { 
			binRemove(\@petsID, $ID); 
			undef %{$pets{$ID}}; 
		} 
		
		if ($type == 0) { 
			$chars[$config{'char'}]{'pet'}{'ID'} = $ID; 
		} elsif ($type == 1) { 
			$chars[$config{'char'}]{'pet'}{'friendly'} = $val; 
			print "Pet Friendly : $chars[$config{'char'}]{'pet'}{'friendly'}\n" if ($config{'debug'});
		} elsif ($type == 2) {
			if ($val <= $config{'petAutoFeedRate'}){
				$petfood = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'petAutoFood'});
				if ($petfood ne "") {
					print "Auto-give pet food : ".$config{'petAutoFood'}."\n";
					sendPetCommand(\$remote_socket, 1);
				} else {
					print "Auto-return to Egg\n";
					sendPetCommand(\$remote_socket, 3);
				}
			}
			$chars[$config{'char'}]{'pet'}{'hungry'} = $val;
			print "Pet Hungry : $chars[$config{'char'}]{'pet'}{'hungry'}\n" if ($config{'debug'});
		} else { 
			if ($chars[$config{'char'}]{'pet'}{'ID'} eq $ID) { 
				if ($type == 3) { 
					$chars[$config{'char'}]{'pet'}{'accessory'} = $val; 
				} elsif ($type == 4) { 
					$chars[$config{'char'}]{'pet'}{'action'} = $val; 
				}
			} else { 
				if (!%{$pets{$ID}}) {
					binAdd(\@petsID, $ID); 
					%{$pets{$ID}} = %{$monsters{$ID}}; 
					$pets{$ID}{'name_given'} = "Unknown"; 
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID); 
				} 
				if ($type == 3) { 
					$pets{$ID}{'accessory'} = $val; 
				} elsif ($type == 4) { 
					$pets{$ID}{'action'} = $val;
				} elsif ($type == 5) {
					print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'}); 
				} 
			} 
		} 
		if (%{$monsters{$ID}}) {
			binRemove(\@monstersID, $ID);
			undef %{$monsters{$ID}};
		}
		print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
#mod Stop
	} elsif ($switch eq "01AA") {
		#pet
		$ID = substr($msg, 2, 4);
		$type = unpack("S1", substr($msg, 6, 2));
		if ($type < 34) {
			print "$pets{$ID}{'name_given'} : $emotions_lut{$type}\n";
		}
	} elsif ($switch eq "01B3") { 
		#NPC image 
		$npc_image = substr($msg, 2,64); 
		($npc_image) = $npc_image =~ /(\S+)/; 
		print "NPC image: $npc_image\n" if $config{'debug'}; 
#mod Start
	} elsif ($switch eq "01B5") { 
		$remain = unpack("L1", substr($msg, 2, 4)); 
		if (!$remain) { 
			$remain = unpack("L1", substr($msg, 6, 4)); 
		}
		$day = int($remain / 1440); 
		$remain = $remain % 1440; 
		$hour = int($remain / 60); 
		$remain = $remain % 60; 
		$minute = $remain; 
		print "You have Airtime : $day days, $hour hours and $minute minutes\n";
		$chars[$config{'char'}]{'Airtime'}{'day'}=$day;
		$chars[$config{'char'}]{'Airtime'}{'hour'}=$hour;
		$chars[$config{'char'}]{'Airtime'}{'minute'}=$minute;
		$chars[$config{'char'}]{'Airtime'}{'loginat'}= getFormattedDate(int(time));
#mod Stop
	} elsif ($switch eq "01B6") {
		#Guild Info 
		$guild{'ID'}        = substr($msg, 2, 4);
		$guild{'lvl'}       = unpack("L1", substr($msg,  6, 4));
		$guild{'conMember'} = unpack("L1", substr($msg, 10, 4));
		$guild{'maxMember'} = unpack("L1", substr($msg, 14, 4));
		$guild{'average'}   = unpack("L1", substr($msg, 18, 4));
		$guild{'exp'}       = unpack("L1", substr($msg, 22, 4));
		$guild{'next_exp'}  = unpack("L1", substr($msg, 26, 4));
		$guild{'members'}   = unpack("L1", substr($msg, 42, 4))+1;
		($guild{'name'})    = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($guild{'master'})  = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;
	} elsif ($switch eq "01B9") { 
		$ID = substr($msg, 2, 4); 
		undef $display; 
		if ($ID eq $accountID) { 
			aiRemove("skill_use"); 
			$display = "You"; 
		} elsif (%{$monsters{$ID}}) { 
			$display = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'})"; 
		} elsif (%{$players{$ID}}) { 
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'})"; 
		} else { 
			$display = "Unknown"; 
		} 
		print "$display failed to use skill\n"; 
	} elsif ($switch eq "01C4") { 
		$index = unpack("S1", substr($msg, 2, 2)); 
		$amount = unpack("L1", substr($msg, 4, 4)); 
		$ID = unpack("S1", substr($msg, 8, 2)); 
		if (%{$storage{'inventory'}[$index]}) { 
			$storage{'inventory'}[$index]{'amount'} += $amount; 
		} else { 
			$storage{'inventory'}[$index]{'nameID'} = $ID; 
			$storage{'inventory'}[$index]{'amount'} = $amount; 
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID; 
			$storage{'inventory'}[$index]{'name'} = $display; 
		}
		print "Storage Item Added: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n"; 
	} elsif ($switch eq "01C8") { 
		$index = unpack("S1",substr($msg, 2, 2)); 
		$ID = unpack("S1", substr($msg, 4, 2)); 
		$sourceID = substr($msg, 6, 4); 
		$amountleft = unpack("S1",substr($msg, 10, 2)); 
		$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID; 
		undef $invIndex; 
		if ($sourceID eq $accountID) { 
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index); 
			$amount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $amountleft; 
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount; 
			print "You used Item: $display x $amount\n"; 
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) { 
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]}; 
			} 
		} elsif (%{$players{$sourceID}}) { 
			print  "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) used $display\n"; 
		} else { 
			print  "Unknown used $display\n"; 
		}
#mod Start
# Encrypt Key
	} elsif ($switch eq "01DC") { 
		$encrypt_key = substr($msg, 4, $msg_size);
#mod Stop
	} elsif ($switch eq "01F4") {
	} elsif (!$rpackets{$switch}) {
		print "Unparsed packet - $switch\n" if $config{'debug'};
	}
#mod Start
# Packet Debugger II
	$lastPacket = substr($msg, 0, $msg_size) if ($config{'debug_packet'} >= 2 && $msg_size);
#mod Stop
	$msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";
	return $msg;
}




#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################

sub ai_clientSuspend {
	my ($type,$initTimeout,@args) = @_;
	my %args;
	$args{'type'} = $type;
	$args{'time'} = time;
	$args{'timeout'} = $initTimeout;
	@{$args{'args'}} = @args;
	unshift @ai_seq, "clientSuspend";
	unshift @ai_seq_args, \%args;
}

sub ai_follow {
	my $name = shift;
	my %args;
	$args{'name'} = $name; 
	unshift @ai_seq, "follow";
	unshift @ai_seq_args, \%args;
}

sub ai_getAggressives {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
		if (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}

sub ai_getIDFromChat {
	my $r_hash = shift;
	my $msg_user = shift;
	my $match_text = shift;
	my $qm;
	if ($match_text !~ /\w+/ || $match_text eq "me") {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			if ($msg_user eq $$r_hash{$_}{'name'}) {
				return $_;
			}
		}
	} else {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			$qm = quotemeta $match_text;
			if ($$r_hash{$_}{'name'} =~ /$qm/i) {
				return $_;
			}
		}
	}
}

sub ai_getMonstersWhoHitMe {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
		if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}
#mod Start
# Skill Type Fix
sub ai_getSkillUseType { 
   my $skill = shift; 
   if ($skill eq "WZ_FIREPILLAR" || $skill eq "WZ_METEOR" 
      || $skill eq "WZ_VERMILION" || $skill eq "WZ_STORMGUST" 
      || $skill eq "WZ_HEAVENDRIVE" || $skill eq "WZ_QUAGMIRE" 
      || $skill eq "MG_SAFETYWALL" || $skill eq "MG_FIREWALL" 
      || $skill eq "MG_THUNDERSTORM" || $skill eq "AL_PNEUMA" 
      || $skill eq "AL_WARP" || $skill eq "PR_SANCTUARY" 
      || $skill eq "PR_MAGNUS"|| $skill eq "BS_HAMMERFALL" 
      || $skill eq "HT_SKIDTRAP" || $skill eq "HT_LANDMINE" 
      || $skill eq "HT_ANKLESNARE" || $skill eq "HT_SHOCKWAVE" 
      || $skill eq "HT_SANDMAN" || $skill eq "HT_FLASHER" 
      || $skill eq "HT_FREEZINGTRAP" || $skill eq "HT_BLASTMINE" 
      || $skill eq "HT_CLAYMORETRAP" || $skill eq "AS_VENOMDUST") { 
      return 1; 
   } else { 
      return 0; 
   } 
}
#mod Stop

sub ai_mapRoute_getRoute {

	my %args;

	##VARS

	$args{'g_normal'} = 1;

	###
	
	my ($returnArray, $r_start_field, $r_start_pos, $r_dest_field, $r_dest_pos, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'r_start_field'} = $r_start_field;
	$args{'r_start_pos'} = $r_start_pos;
	$args{'r_dest_field'} = $r_dest_field;
	$args{'r_dest_pos'} = $r_dest_pos;
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	unshift @ai_seq, "route_getMapRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_mapRoute_getSuccessors {
	my ($r_args, $r_array, $r_cur) = @_;
	my $ok;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}

			&& !($$r_cur{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})

			&& !(%{$$r_cur{'parent'}} && $$r_cur{'parent'}{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})) {
			undef $ok;
			if (!%{$$r_cur{'parent'}}) {
				if (!$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}}, 
							$$r_args{'start'}{'dest'}{'field'}, \%{$$r_args{'start'}{'dest'}{'pos'}}, \%{$portals_lut{$_}{'source'}{'pos'}});
					last;
				}
				$ok = 1 if (@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}});
			} elsif ($portals_los{$$r_cur{'dest'}{'ID'}}{$portals_lut{$_}{'source'}{'ID'}} ne "0"
				&& $portals_los{$portals_lut{$_}{'source'}{'ID'}}{$$r_cur{'dest'}{'ID'}} ne "0") {
				$ok = 1;
			}
			if ($$r_args{'dest'}{'source'}{'pos'}{'x'} ne "" && $portals_lut{$_}{'dest'}{'map'} eq $$r_args{'dest'}{'source'}{'map'}) {
				if (!$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}, 
							$$r_args{'dest'}{'source'}{'field'}, \%{$portals_lut{$_}{'dest'}{'pos'}}, \%{$$r_args{'dest'}{'source'}{'pos'}});
					last;
				}
			}
			push @{$r_array}, \%{$portals_lut{$_}} if $ok;
		}
	}
}

sub ai_mapRoute_searchStep {
	my $r_args = shift;
	my @successors;
	my $r_cur, $r_suc;
	my $i;

	###check if failed
	if (!@{$$r_args{'openList'}}) {
		#failed!
		$$r_args{'done'} = 1;
		return;
	}
	
	$r_cur = shift @{$$r_args{'openList'}};

	###check if finished
	if ($$r_args{'dest'}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}
		&& (@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$$r_cur{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}
		|| $$r_args{'dest'}{'source'}{'pos'}{'x'} eq "")) {
		do {
			unshift @{$$r_args{'solutionList'}}, {%{$r_cur}};
			$r_cur = $$r_cur{'parent'} if (%{$$r_cur{'parent'}});
		} while ($r_cur != \%{$$r_args{'start'}});
		$$r_args{'done'} = 1;
		return;
	}

	ai_mapRoute_getSuccessors($r_args, \@successors, $r_cur);
	if ($$r_args{'waitingForSolution'}) {
		undef $$r_args{'waitingForSolution'};
		unshift @{$$r_args{'openList'}}, $r_cur;
		return;
	}

	$newg = $$r_cur{'g'} + $$r_args{'g_normal'};
	foreach $r_suc (@successors) {
		undef $found;
		undef $openFound;
		undef $closedFound;
		for($i = 0; $i < @{$$r_args{'openList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'openList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'openList'}[$i]{'g'}) {
					$found = 1;
					}
				$openFound = $i;
				last;
			}
		}
		next if ($found);
		
		undef $found;
		for($i = 0; $i < @{$$r_args{'closedList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'closedList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'closedList'}[$i]{'g'}) {
					$found = 1;
				}
				$closedFound = $i;
				last;
			}
		}
		next if ($found);
		if ($openFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'openList'}}, $openFound);
		}
		if ($closedFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'closedList'}}, $closedFound);
		}
		$$r_suc{'g'} = $newg;
		$$r_suc{'h'} = 0;
		$$r_suc{'f'} = $$r_suc{'g'} + $$r_suc{'h'};
		$$r_suc{'parent'} = $r_cur;
		minHeapAdd(\@{$$r_args{'openList'}}, $r_suc, "f");
	}
	push @{$$r_args{'closedList'}}, $r_cur;
}

sub ai_items_take {
	my ($x1, $y1, $x2, $y2) = @_;
	my %args;
	$args{'pos'}{'x'} = $x1;
	$args{'pos'}{'y'} = $y1;
	$args{'pos_to'}{'x'} = $x2;
	$args{'pos_to'}{'y'} = $y2;
	$args{'ai_items_take_end'}{'time'} = time;
	$args{'ai_items_take_end'}{'timeout'} = $timeout{'ai_items_take_end'}{'timeout'};
	$args{'ai_items_take_start'}{'time'} = time;
	$args{'ai_items_take_start'}{'timeout'} = $timeout{'ai_items_take_start'}{'timeout'};
	unshift @ai_seq, "items_take";
	unshift @ai_seq_args, \%args;
}

sub ai_route {
	my ($r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals) = @_;
	my %args;	
#mod Start
	my $pos_x;
	my $pos_y;
	$pos_x = int($chars[$config{'char'}]{'pos_to'}{'x'}) if ($chars[$config{'char'}]{'pos_to'}{'x'} ne "");
	$pos_y = int($chars[$config{'char'}]{'pos_to'}{'y'}) if ($chars[$config{'char'}]{'pos_to'}{'y'} ne "");
#mod Stop
	$x = int($x) if ($x ne "");
	$y = int($y) if ($y ne "");
	$args{'returnHash'} = $r_ret;
	$args{'dest_x'} = $x;
	$args{'dest_y'} = $y;
	$args{'dest_map'} = $map;
	$args{'maxRouteDistance'} = $maxRouteDistance;
	$args{'maxRouteTime'} = $maxRouteTime;
	$args{'attackOnRoute'} = $attackOnRoute;
	$args{'avoidPortals'} = $avoidPortals;
	$args{'distFromGoal'} = $distFromGoal;
	$args{'checkInnerPortals'} = $checkInnerPortals;
	undef %{$args{'returnHash'}};
	unshift @ai_seq, "route";
	unshift @ai_seq_args, \%args;
	print "On route to: $maps_lut{$map.'.rsw'}($map): $x, $y\n" if $config{'debug'};
#mod Start
#if kore is stuck
	if (($old_x == $x) && ($old_y == $y)) {
		$calcTo_SameSpot++;
	} else {
		$calcTo_SameSpot = 0;
		$old_x = $x;
		$old_y = $y;
	}
	if ($calcTo_SameSpot >= 10) {
		$calcTo_SameSpot = 0;
		Unstuck("Cannot find destination, trying to unstuck ...\n");
	}
	
	if (($old_pos_x == $pos_x) && ($old_pos_y == $pos_y)) {
		$calcFrom_SameSpot++;
	} else {
		$calcFrom_SameSpot = 0;
		$old_pos_x = $pos_x;
		$old_pos_y = $pos_y;
	}
	if ($calcFrom_SameSpot >= 10) {
		$calcFrom_SameSpot = 0;
		Unstuck("Invalid original position, trying to unstuck ...\n");
	}	

	if ($totalStuckCount >= 10) {
		RespawnUnstuck();
	}	
#mod Stop
}

sub ai_route_getDiagSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;

	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}	

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}	

		
	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}	
}

sub ai_route_getMap {
	my $r_args = shift;
	my $x = shift;
	my $y = shift;
	if($x < 0 || $x >= $$r_args{'field'}{'width'} || $y < 0 || $y >= $$r_args{'field'}{'height'}) {
		return 1;	 
	}
	return $$r_args{'field'}{'field'}[($y*$$r_args{'field'}{'width'})+$x];
}

sub ai_route_getRoute {
	my %args;
	my ($returnArray, $r_field, $r_start, $r_dest, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'field'} = $r_field;
	%{$args{'start'}} = %{$r_start};
	%{$args{'dest'}} = %{$r_dest};
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	$args{'destroyFunction'} = \&ai_route_getRoute_destroy;
	undef @{$args{'returnArray'}};
	unshift @ai_seq, "route_getRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_route_getRoute_destroy {
	my $r_args = shift;
	if (!$config{'buildType'}) {
		$CalcPath_destroy->Call($$r_args{'session'}) if ($$r_args{'session'} ne "");
	} elsif ($config{'buildType'} == 1) {
		&{$CalcPath_destroy}($$r_args{'session'}) if ($$r_args{'session'} ne "");
	}
}
sub ai_route_searchStep {
	my $r_args = shift;
	my $ret;

	if (!$$r_args{'initialized'}) {
		#####
		my $SOLUTION_MAX = 5000;
		$$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
		#####
		if (!$config{'buildType'}) {
			$$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
				$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'}, 
				pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
		} elsif ($config{'buildType'} == 1) {
			$$r_args{'session'} = &{$CalcPath_init}($$r_args{'solution'},
				$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'}, 
				pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});

		}
	}
	if ($$r_args{'session'} < 0) {
		$$r_args{'done'} = 1;
		return;
	}
	$$r_args{'initialized'} = 1;
	if (!$config{'buildType'}) {
		$ret = $CalcPath_pathStep->Call($$r_args{'session'});
	} elsif ($config{'buildType'} == 1) {
		$ret = &{$CalcPath_pathStep}($$r_args{'session'});
	}
	if (!$ret) {
		my $size = unpack("L",substr($$r_args{'solution'},0,4));
		my $j = 0;
		my $i;
		for ($i = ($size-1)*4+4; $i >= 4;$i-=4) {
			$$r_args{'returnArray'}[$j]{'x'} = unpack("S",substr($$r_args{'solution'}, $i, 2));
			$$r_args{'returnArray'}[$j]{'y'} = unpack("S",substr($$r_args{'solution'}, $i+2, 2));
			$j++;
		}
		$$r_args{'done'} = 1;
	}
}

sub ai_route_getSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;
	
	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}	

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}	

		
	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}	
}

#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
		if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
			return 1;
		}
	}
}

sub ai_setMapChanged {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'mapChanged'} = time;
	}
	$ai_v{'portalTrace_mapChanged'} = 1;
}

sub ai_setSuspend {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'suspended'} = time;
	}
}

sub ai_skillUse {
	my $ID = shift;
	my $lv = shift;
	my $maxCastTime = shift;
	my $minCastTime = shift;
	my $target = shift;
	my $y = shift;
	my %args;
	$args{'ai_skill_use_giveup'}{'time'} = time;
	$args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
	$args{'skill_use_id'} = $ID;
	$args{'skill_use_lv'} = $lv;
	$args{'skill_use_maxCastTime'}{'time'} = time;
	$args{'skill_use_maxCastTime'}{'timeout'} = $maxCastTime;
	$args{'skill_use_minCastTime'}{'time'} = time;
	$args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;
	if ($y eq "") {
		$args{'skill_use_target'} = $target;
	} else {
		$args{'skill_use_target_x'} = $target;
		$args{'skill_use_target_y'} = $y;
	}
	unshift @ai_seq, "skill_use";
	unshift @ai_seq_args, \%args;
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
		if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
			return 1;
		}
	}
}

sub attack {
	my $ID = shift;
	my %args;
	$args{'ai_attack_giveup'}{'time'} = time;
	$args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
	%{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
	unshift @ai_seq, "attack";
	unshift @ai_seq_args, \%args;
	print "Attacking: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n";
#Mod Start
AUTOEQUIP: {
	my $i = 0;
	my $Req;
	my $Leq;
	my $arrow;
	while ($config{"autoSwitch_monsters_$i"} ne "") { 
		if (existsInList($config{"autoSwitch_monsters_$i"}, $monsters{$ID}{'name'})) {
			print "Encounter Monster : ".$monsters{$ID}{'name'}."\n";
			$Req = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_Rnew_$i"}) if ($config{"autoSwitch_Rnew_$i"});
			$Leq = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_Lnew_$i"}) if ($config{"autoSwitch_Lnew_$i"});
			$arrow = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_Anew_$i"}) if ($config{"autoSwitch_Anew_$i"});
			if ($Leq ne "" && !$chars[$config{'char'}]{'inventory'}[$Leq]{'equipped'}) { 
				print "Auto Equiping [L] :".$config{"autoSwitch_Lnew_$i"}."\n"; 
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$Leq]{'index'},$chars[$config{'char'}]{'inventory'}[$Leq]{'type_equip'}); 
			}
			if ($Req ne "" && !$chars[$config{'char'}]{'inventory'}[$Req]{'equipped'}) { 
				print "Auto Equiping [R] :".$config{"autoSwitch_Rnew_$i"}."\n"; 
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$Req]{'index'},$chars[$config{'char'}]{'inventory'}[$Req]{'type_equip'}); 
			}
			if ($arrow ne "" && $chars[$config{'char'}]{'inventory'}[$arrow]{'equipped'} eq "") { 
				print "Auto Equiping [A] :".$config{"autoSwitch_Anew_$i"}."\n"; 
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arrow]{'index'}, 0); 
			}
			last AUTOEQUIP; 
		}
		$i++;
	}
	if ($config{'autoSwitch_Rdef'}) { 
		$Req = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'autoSwitch_Rdef'}); 
		if($Req ne "" && !$chars[$config{'char'}]{'inventory'}[$Req]{'equipped'}) {
			print "Auto equiping default [R] :".$config{'autoSwitch_Rdef'}."\n"; 
			sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$Req]{'index'},$chars[$config{'char'}]{'inventory'}[$Req]{'type_equip'});
		}
	}
	if ($config{'autoSwitch_Ldef'} && $chars[$config{'char'}]{'inventory'}[$Req]{'equipped'} !=34) { 
		$Leq = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'autoSwitch_Ldef'}); 
		if($Leq ne "" && !$chars[$config{'char'}]{'inventory'}[$Leq]{'equipped'}) {
			print "Auto equiping default [L] :".$config{'autoSwitch_Ldef'}."\n"; 
			sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$Leq]{'index'},$chars[$config{'char'}]{'inventory'}[$Leq]{'type_equip'});
		}
	}elsif ($config{'autoSwitch_Ldef'}){
		print "Cannot Equip Left Hand Because You Eq 2H Weapon\n";
	}
	if ($config{'autoSwitch_Adef'}) { 
		$arrow = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'autoSwitch_Adef'}); 
		if($arrow ne "" && $chars[$config{'char'}]{'inventory'}[$arrow]{'equipped'} eq "") {
			print "Auto equiping default [A] :".$config{'autoSwitch_Adef'}."\n"; 
			sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arrow]{'index'}, 0, 0);
		}
	}
} #END OF BLOCK AUTOEQUIP 
#Mod Stop
}

sub aiRemove {
	my $ai_type = shift;
	my $index;
	while (1) {
		$index = binFind(\@ai_seq, $ai_type);
		if ($index ne "") {
			if ($ai_seq_args[$index]{'destroyFunction'}) {
				&{$ai_seq_args[$index]{'destroyFunction'}}(\%{$ai_seq_args[$index]});
			}
			binRemoveAndShiftByIndex(\@ai_seq, $index);
			binRemoveAndShiftByIndex(\@ai_seq_args, $index);
		} else {
			last;
		}
	}
}


sub gather {
	my $ID = shift;
	my %args;
	$args{'ai_items_gather_giveup'}{'time'} = time;
	$args{'ai_items_gather_giveup'}{'timeout'} = $timeout{'ai_items_gather_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "items_gather";
	unshift @ai_seq_args, \%args;
	print "Targeting for Gather: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
}


sub look {
	my $body = shift;
	my $head = shift;
	my %args;
	unshift @ai_seq, "look";
	$args{'look_body'} = $body;
	$args{'look_head'} = $head;
	unshift @ai_seq_args, \%args;
}

sub move {
	my $x = shift;
	my $y = shift;
#mod Start
	my $pos_x;
	my $pos_y;
	$pos_x = int($chars[$config{'char'}]{'pos_to'}{'x'}) if ($chars[$config{'char'}]{'pos_to'}{'x'} ne "");
	$pos_y = int($chars[$config{'char'}]{'pos_to'}{'y'}) if ($chars[$config{'char'}]{'pos_to'}{'y'} ne "");
#mod Stop
	my %args;
	$args{'move_to'}{'x'} = $x;
	$args{'move_to'}{'y'} = $y;
	$args{'ai_move_giveup'}{'time'} = time;
	$args{'ai_move_giveup'}{'timeout'} = $timeout{'ai_move_giveup'}{'timeout'};
	unshift @ai_seq, "move";
	unshift @ai_seq_args, \%args;
#mod Start
#if kore is stuck
	if (($move_x == $x) && ($move_y == $y)) {
		$moveTo_SameSpot++;
	} else {
		$moveTo_SameSpot = 0;
		$move_x = $x;
		$move_y = $y;
	}
	if ($moveTo_SameSpot == 20) {
		ClearRouteAI("Keep trying to move to same spot, clearing route AI to unstuck ...\n");
	}
	if ($moveTo_SameSpot >= 50) {
		$moveTo_SameSpot = 0;
		Unstuck("Keep trying to move to same spot, teleporting to unstuck ...\n");
	}

	if (($move_pos_x == $pos_x) && ($move_pos_y == $pos_y)) {
		$moveFrom_SameSpot++;
	} else {
		$moveFrom_SameSpot = 0;
		$move_pos_x = $pos_x;
		$move_pos_y = $pos_y;
	}
	if ($moveFrom_SameSpot == 20) {
		ClearRouteAI("Keep trying to move from same spot, clearing route AI to unstuck ...\n");
	}
	if ($moveFrom_SameSpot >= 50) {
		$moveFrom_SameSpot = 0;
		Unstuck("Keep trying to move from same spot, teleport to unstuck ...\n");
	}											    

	if ($totalStuckCount >= 10) {
		RespawnUnstuck();
	}	
#mod Stop
}

sub quit {
	$quit = 1;
	print "Exiting...\n";
}

sub relog {
	$conState = 1;
	undef $conState_tries;
	print "Relogging\n";
}

sub sendMessage {
	my $r_socket = shift;
	my $type = shift;
	my $msg = shift;
	my $user = shift;
	my $i, $j;
	my @msg;
	my @msgs;
	my $oldmsg;
	my $amount;
	my $space;
	@msgs = split /\\n/,$msg;
	for ($j = 0; $j < @msgs; $j++) {
	@msg = split / /, $msgs[$j];
	undef $msg;
	for ($i = 0; $i < @msg; $i++) {
		if (!length($msg[$i])) {
			$msg[$i] = " ";
			$space = 1;
		}
		if (length($msg[$i]) > $config{'message_length_max'}) {
			while (length($msg[$i]) >= $config{'message_length_max'}) {
				$oldmsg = $msg;
				if (length($msg)) {
					$amount = $config{'message_length_max'};
					if ($amount - length($msg) > 0) {
						$amount = $config{'message_length_max'} - 1;
						$msg .= " " . substr($msg[$i], 0, $amount - length($msg));
					}
				} else {
					$amount = $config{'message_length_max'};
					$msg .= substr($msg[$i], 0, $amount);
				}
				if ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") { 
					sendGuildChat($r_socket, $msg); 
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					sendPrivateMsg($r_socket, $user, $msg);
					undef %lastpm;
					$lastpm{'msg'} = $msg;
					$lastpm{'user'} = $user;
					push @lastpm, {%lastpm};
				}
				$msg[$i] = substr($msg[$i], $amount - length($oldmsg), length($msg[$i]) - $amount - length($oldmsg));
				undef $msg;
			}
		}
		if (length($msg[$i]) && length($msg) + length($msg[$i]) <= $config{'message_length_max'}) {
			if (length($msg)) {
				if (!$space) {
					$msg .= " " . $msg[$i];
				} else {
					$space = 0;
					$msg .= $msg[$i];
				}
			} else {
				$msg .= $msg[$i];
			}
		} else {
			if ($type eq "c") {
				sendChat($r_socket, $msg);
			} elsif ($type eq "g") { 
				sendGuildChat($r_socket, $msg); 
			} elsif ($type eq "p") {
				sendPartyChat($r_socket, $msg);
			} elsif ($type eq "pm") {
				sendPrivateMsg($r_socket, $user, $msg);
				undef %lastpm;
				$lastpm{'msg'} = $msg;
				$lastpm{'user'} = $user;
				push @lastpm, {%lastpm};
			}
			$msg = $msg[$i];
		}
		if (length($msg) && $i == @msg - 1) {
			if ($type eq "c") {
				sendChat($r_socket, $msg);
			} elsif ($type eq "g") { 
				sendGuildChat($r_socket, $msg); 
			} elsif ($type eq "p") {
				sendPartyChat($r_socket, $msg);
			} elsif ($type eq "pm") {
				sendPrivateMsg($r_socket, $user, $msg);
				undef %lastpm;
				$lastpm{'msg'} = $msg;
				$lastpm{'user'} = $user;
				push @lastpm, {%lastpm};
			}
		}
	}
	}
}

sub sit {
	$timeout{'ai_sit_wait'}{'time'} = time;
	unshift @ai_seq, "sitting";
	unshift @ai_seq_args, {};
}

sub stand {
	unshift @ai_seq, "standing";
	unshift @ai_seq_args, {};
}

sub take {
	my $ID = shift;
	my %args;
	$args{'ai_take_giveup'}{'time'} = time;
	$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "take";
	unshift @ai_seq_args, \%args;
	print "Targeting for Pickup: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
}

#Karusu
#mod Start
# Teleport Fix
sub useTeleport { 
	my $level = shift;
	my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 600 + $level);
	undef $teleQueue; 

	# Closing Chatroom Before Teleporting
	if ($currentChatRoom ne ""){
		sendChatRoomLeave(\$remote_socket);
	}
	# Stand up before teleporting 
	if ($chars[$config{'char'}]{'sitting'}) { 
		sendStand(\$remote_socket); 
		sleep(0.5); 
	}

	if (!$config{'teleportAuto_useItem'} || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}) {
		sendTeleport(\$remote_socket, "Random") if ($level == 1); 
		sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2); 
	} elsif ($invIndex ne "") { 
		sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID); 
		# Wait for the inventory info to come 
	} elsif (!scalar(@{$chars[$config{'char'}]{'inventory'}})) { 
		$teleQueue = $level; 
	} else { 
		print "Can't teleport or respawn - need wing or skill\n";
	} 

} 
#mod Stop

#######################################
#######################################
#AI MATH
#######################################
#######################################


sub distance {
	my $r_hash1 = shift;
	my $r_hash2 = shift;
	my %line;
	if ($r_hash2) {
		$line{'x'} = abs($$r_hash1{'x'} - $$r_hash2{'x'});
		$line{'y'} = abs($$r_hash1{'y'} - $$r_hash2{'y'});
	} else {
		%line = %{$r_hash1};
	}
	return sqrt($line{'x'} ** 2 + $line{'y'} ** 2);
}

sub getVector {
	my $r_store = shift;
	my $r_head = shift;
	my $r_tail = shift;
	$$r_store{'x'} = $$r_head{'x'} - $$r_tail{'x'};
	$$r_store{'y'} = $$r_head{'y'} - $$r_tail{'y'};
}

sub lineIntersection {
	my $r_pos1 = shift;
	my $r_pos2 = shift;
	my $r_pos3 = shift;
	my $r_pos4 = shift;
	my $x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4, $result, $result1, $result2;
	$x1 = $$r_pos1{'x'};
	$y1 = $$r_pos1{'y'};
	$x2 = $$r_pos2{'x'};
	$y2 = $$r_pos2{'y'};
	$x3 = $$r_pos3{'x'};
	$y3 = $$r_pos3{'y'};
	$x4 = $$r_pos4{'x'};
	$y4 = $$r_pos4{'y'};
	$result1 = ($x4 - $x3)*($y1 - $y3) - ($y4 - $y3)*($x1 - $x3);
	$result2 = ($y4 - $y3)*($x2 - $x1) - ($x4 - $x3)*($y2 - $y1);
	if ($result2 != 0) {
		$result = $result1 / $result2;
	}
	return $result;
}


sub moveAlongVector {
	my $r_store = shift;
	my $r_pos = shift;
	my $r_vec = shift;
	my $amount = shift;
	my %norm;
	if ($amount) {
		normalize(\%norm, $r_vec);
		$$r_store{'x'} = $$r_pos{'x'} + $norm{'x'} * $amount;
		$$r_store{'y'} = $$r_pos{'y'} + $norm{'y'} * $amount;
	} else {
		$$r_store{'x'} = $$r_pos{'x'} + $$r_vec{'x'};
		$$r_store{'y'} = $$r_pos{'y'} + $$r_vec{'y'};
	}
}

sub normalize {
	my $r_store = shift;
	my $r_vec = shift;
	my $dist;
	$dist = distance($r_vec);
	if ($dist > 0) {
		$$r_store{'x'} = $$r_vec{'x'} / $dist;
		$$r_store{'y'} = $$r_vec{'y'} / $dist;
	} else {
		$$r_store{'x'} = 0;
		$$r_store{'y'} = 0;
	}
}

sub percent_hp {
	my $r_hash = shift;
	if (!$$r_hash{'hp_max'}) {
		return 0;
	} else {
		return ($$r_hash{'hp'} / $$r_hash{'hp_max'} * 100);
	}
}

sub percent_sp {
	my $r_hash = shift;
	if (!$$r_hash{'sp_max'}) {
		return 0;
	} else {
		return ($$r_hash{'sp'} / $$r_hash{'sp_max'} * 100);
	}
}

sub percent_weight {
	my $r_hash = shift;
	if (!$$r_hash{'weight_max'}) {
		return 0;
	} else {
		return ($$r_hash{'weight'} / $$r_hash{'weight_max'} * 100);
	}
}

#######################################
#######################################
#CONFIG MODIFIERS
#######################################
#######################################

sub auth {
	my $user = shift;
	my $flag = shift;
	if ($flag) {
		print "Authorized user '$user' for admin\n";
	} else {
		print "Revoked admin privilages for user '$user'\n";
	}	
	$overallAuth{$user} = $flag;
	writeDataFile("control/overallAuth.txt", \%overallAuth);
}

sub configModify {
	my $key = shift;
	my $val = shift;
	print "Config '$key' set to $val\n";
	$config{$key} = $val;
	writeDataFileIntact("$def_config/config.txt", \%config);
}

sub setTimeout {
	my $timeout = shift;
	my $time = shift;
	$timeout{$timeout}{'timeout'} = $time;
	print "Timeout '$timeout' set to $time\n";
	writeDataFileIntact2("control/timeouts.txt", \%timeout);
}


#######################################
#######################################
#OUTGOING PACKET FUNCTIONS
#######################################
#######################################

sub decrypt {
	my $r_msg = shift;
	my $themsg = shift;
	my @mask;
	my $i;
	my ($temp, $msg_temp, $len_add, $len_total, $loopin, $len, $val);
	if ($config{'encrypt'} == 1) {
		undef $$r_msg;
		undef $len_add;
		undef $msg_temp;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		$len = unpack("S1",substr($themsg,0,2));
		$val = unpack("S1",substr($themsg,2,2));
		{
			use integer;
			$temp = ($val * $val * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $val * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for($loopin = 0; ($loopin + 4) < $len; $loopin++) {
 			if (!($mask[$loopin % 13])) {
  				$msg_temp .= substr($themsg,$loopin + 4,1);
			}
		}
		if (($len - 4) % 8 != 0) {
			$len_add = 8 - (($len - 4) % 8);
		}
		$len_total = $len + $len_add;
		$$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
	} elsif ($config{'encrypt'} >= 2) {
		undef $$r_msg;
		undef $len_add;
		undef $msg_temp;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		$len = unpack("S1",substr($themsg,0,2));
		$val = unpack("S1",substr($themsg,2,2));
		{
			use integer;
			$temp = ($val * $val * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $val * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for($loopin = 0; ($loopin + 4) < $len; $loopin++) {
 			if (!($mask[$loopin % 17])) {
  				$msg_temp .= substr($themsg,$loopin + 4,1);
			}
		}
		if (($len - 4) % 8 != 0) {
			$len_add = 8 - (($len - 4) % 8);
		}
		$len_total = $len + $len_add;
		$$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
	} else {
		$$r_msg = $themsg;
	}
}

sub encrypt {
	my $r_socket = shift;
	my $themsg = shift;
	my @mask;
	my $newmsg;
	my ($in, $out);
	if ($config{'encrypt'} == 1 && $conState >= 5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 13]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} elsif ($config{'encrypt'} >= 2 && $conState >= 5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 17]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} else {
		$newmsg = $themsg;
	}
	$$r_socket->send($newmsg) if $$r_socket && $$r_socket->connected();
}

sub sendAddSkillPoint {
	my $r_socket = shift;
	my $skillID = shift;
	my $msg = pack("C*", 0x12, 0x01) . pack("S*", $skillID);
	encrypt($r_socket, $msg);
}

sub sendAddStatusPoint {
	my $r_socket = shift;
	my $statusID = shift;
	my $msg = pack("C*", 0xBB, 0) . pack("S*", $statusID) . pack("C*", 0x01);
	encrypt($r_socket, $msg);
}

sub sendAlignment {
	my $r_socket = shift;
	my $ID = shift;
	my $alignment = shift;
	my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
	encrypt($r_socket, $msg);
	print "Sent Alignment: ".getHex($ID).", $alignment\n" if ($config{'debug'} >= 2);
}

sub sendAttack {
	my $r_socket = shift;
	my $monID = shift;
	my $flag = shift;
        my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent attack: ".getHex($monID)."\n" if ($config{'debug'} >= 2);
}

sub sendAttackStop {
	my $r_socket = shift;
        my $msg = pack("C*", 0x18, 0x01);
	encrypt($r_socket, $msg);
	print "Sent stop attack\n" if $config{'debug'};
}

sub sendBuy {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
	encrypt($r_socket, $msg);
	print "Sent buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendCartAdd {  
	my $r_socket = shift;  
	my $index = shift;  
	my $amount = shift;
	my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount); 
	encrypt($r_socket, $msg);  
	print "Sent Cart Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGet {  
	my $r_socket = shift;  
	my $index = shift;  
	my $amount = shift;
	my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount); 
	encrypt($r_socket, $msg);  
	print "Sent Cart Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCharLogin {
	my $r_socket = shift;
	my $char = shift;
	my $msg = pack("C*", 0x66,0) . pack("C*",$char);
	encrypt($r_socket, $msg);
}

sub sendChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) . 
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendChatRoomBestow {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Chat Room Bestow: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomChange {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xDE, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
	encrypt($r_socket, $msg);
	print "Sent Change Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomCreate {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD5, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
	encrypt($r_socket, $msg);
	print "Sent Create Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
	encrypt($r_socket, $msg);
	print "Sent Join Chat Room: ".getHex($ID)." $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE2, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Chat Room Kick: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE3, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Leave Chat Room\n" if ($config{'debug'} >= 2);
}

sub sendCurrentDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xED, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Cancel Current Deal\n" if ($config{'debug'} >= 2);
}

sub sendDeal {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xE4, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Initiate Deal: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendDealAccept {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x03);
	encrypt($r_socket, $msg);
	print "Sent Accept Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*",$amount);	
	encrypt($r_socket, $msg);
	print "Sent Deal Add Item: $index, $amount\n" if ($config{'debug'} >= 2);
}

sub sendDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x04);
	encrypt($r_socket, $msg);
	print "Sent Cancel Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealOK {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealTrade {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEF, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal Trade\n" if ($config{'debug'} >= 2);
}

sub sendDrop {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
	encrypt($r_socket, $msg);
	print "Sent drop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendEmotion {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xBF, 0x00).pack("C1",$ID);
	encrypt($r_socket, $msg);
	print "Sent Emotion\n" if ($config{'debug'} >= 2);
}

sub sendEquip{
	my $r_socket = shift;
	my $index = shift;
	my $type = shift;
	my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) .  pack("S*", $type);
	encrypt($r_socket, $msg);
	print "Sent Equip: $index\n" if ($config{'debug'} >= 2);
}

sub sendGameLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $sessionID = shift;
	my $sessionID2 = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . $sessionID2 . pack("C*", 0,0,$sex);
	encrypt($r_socket, $msg);
}

sub sendGetPlayerInfo {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x94, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent get player info: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
	encrypt($r_socket, $msg);
	print "Sent get store list: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetSellList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
	encrypt($r_socket, $msg);
	print "Sent sell to NPC: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildChat { 
	my $r_socket = shift; 
	my $message = shift; 
	my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) . 
	$chars[$config{'char'}]{'name'} . " : " . $message . chr(0); 
	encrypt($r_socket, $msg); 
} 

sub sendIdentify {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Identify: $index\n" if ($config{'debug'} >= 2);
}

sub sendIgnore {
	my $r_socket = shift;
	my $name = shift;
	my $flag = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Ignore: $name, $flag\n" if ($config{'debug'} >= 2);
}

sub sendIgnoreAll { 
	my $r_socket = shift; 
	my $flag = shift; 
	my $msg = pack("C*", 0xD0, 0x00).pack("C*", $flag); 
	encrypt($r_socket, $msg); 
	print "Sent Ignore All: $flag\n" if ($config{'debug'} >= 2); 
}

#sendGetIgnoreList - chobit 20021223 
sub sendIgnoreListGet {  
	my $r_socket = shift;  
	my $flag = shift;  
	my $msg = pack("C*", 0xD3, 0x00);  
	encrypt($r_socket, $msg); 
	print "Sent get Ignore List: $flag\n" if ($config{'debug'} >= 2);
}

sub sendItemUse {
	my $r_socket = shift;
	my $ID = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0xA7, 0x00).pack("S*",$ID).$targetID;
	encrypt($r_socket, $msg);
	print "Item Use: $ID\n" if ($config{'debug'} >= 2);
}


sub sendLook {
	my $r_socket = shift;
	my $body = shift;
	my $head = shift;
	my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
	encrypt($r_socket, $msg);
	print "Sent look: $body $head\n" if ($config{'debug'} >= 2);
	$chars[$config{'char'}]{'look'}{'head'} = $head;
	$chars[$config{'char'}]{'look'}{'body'} = $body;
}

sub sendMapLoaded {
	my $r_socket = shift;
	my $msg = pack("C*", 0x7D,0x00);
	print "Sending Map Loaded\n" if $config{'debug'};
	encrypt($r_socket, $msg);
}

sub sendMapLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $charID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
	encrypt($r_socket, $msg);
}

sub sendMasterLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $msg = pack("C*", 0x64,0,$config{'version'},0,0,0) . $username . chr(0) x (24 - length($username)) . 
			$password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt($r_socket, $msg);
}

sub sendMemo {
	my $r_socket = shift;
	my $msg = pack("C*", 0x1D, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Memo\n" if ($config{'debug'} >= 2);
}

sub sendMove {
	my $r_socket = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
	encrypt($r_socket, $msg);
	print "Sent move to: $x, $y\n" if ($config{'debug'} >= 2);
}

sub sendPartyChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) . 
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendPartyJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xFF, 0x00).$ID.pack("L", $flag);
	encrypt($r_socket, $msg);
	print "Sent Join Party: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xFC, 0x00).$ID;
	encrypt($r_socket, $msg);
	print "Sent Request Join Party: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyKick {
	my $r_socket = shift;
	my $ID = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0x03, 0x01).$ID.$name;
	encrypt($r_socket, $msg);
	print "Sent Kick Party: ".getHex($ID).", $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0x00, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Leave Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Organize Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x02, 0x01).pack("L", $flag);
	encrypt($r_socket, $msg);
	print "Sent Party Share: $flag\n" if ($config{'debug'} >= 2);
}

sub sendRaw {
	my $r_socket = shift;
	my $raw = shift;
	my @raw;
	my $msg;
	@raw = split / /, $raw;
	foreach (@raw) {
		$msg .= pack("C", hex($_));
	}
	encrypt($r_socket, $msg);
	print "Sent Raw Packet: @raw\n" if ($config{'debug'} >= 2);
}

sub sendRespawn {
	my $r_socket = shift;
	my $msg = pack("C*", 0xB2, 0x00, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Respawn\n" if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
	my $r_socket = shift;
	my $user = shift;
	my $message = shift;
	my $msg = pack("C*",0x96, 0x00) . pack("S*",length($message) + 29) . $user . chr(0) x (24 - length($user)) .
			$message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendSell {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
	encrypt($r_socket, $msg);
	print "Sent sell: $index x $amount\n" if ($config{'debug'} >= 2);
	
}

sub sendSit {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
	encrypt($r_socket, $msg);
	print "Sitting\n" if ($config{'debug'} >= 2);
}

sub sendSkillUse {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x13, 0x01).pack("S*",$lv,$ID).$targetID;
	encrypt($r_socket, $msg);
	print "Skill Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendSkillUseLoc {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x16, 0x01).pack("S*",$lv,$ID,$x,$y);
	encrypt($r_socket, $msg);
	print "Skill Use Loc: $ID\n" if ($config{'debug'} >= 2);
}

sub sendStorageAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);	
}

sub sendStorageClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0xF7, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Storage Done\n" if ($config{'debug'} >= 2);
}

sub sendStorageGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Get: $index x $amount\n" if ($config{'debug'} >= 2);	
}

sub sendStand {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
	encrypt($r_socket, $msg);
	print "Standing\n" if ($config{'debug'} >= 2);
}

sub sendSync {
	my $r_socket = shift;
	my $time = shift;
	my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
	encrypt($r_socket, $msg);
	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
}

sub sendTake {
	my $r_socket = shift;
	my $itemID = shift;
	my $msg = pack("C*", 0x9F, 0x00) . $itemID;
	encrypt($r_socket, $msg);
	print "Sent take\n" if ($config{'debug'} >= 2);
}

sub sendTalk {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*",0x01);
	encrypt($r_socket, $msg);
	print "Sent talk: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkCancel {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x46, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent talk cancel: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xB9, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent talk continue: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
	my $r_socket = shift;
	my $ID = shift;
	my $response = shift;
	my $msg = pack("C*", 0xB8, 0x00) . $ID. pack("C1",$response);
	encrypt($r_socket, $msg);
	print "Sent talk respond: ".getHex($ID).", $response\n" if ($config{'debug'} >= 2);
}

sub sendTeleport {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
	encrypt($r_socket, $msg);
	print "Sent Teleport: $location\n" if ($config{'debug'} >= 2);
}

sub sendUnequip{
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Unequip: $index\n" if ($config{'debug'} >= 2);
}

sub sendWho {
	my $r_socket = shift;
	my $msg = pack("C*", 0xC1, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Who\n" if ($config{'debug'} >= 2);
}




#######################################
#######################################
#CONNECTION FUNCTIONS
#######################################
#######################################


sub connection {
	my $r_socket = shift;
	my $host = shift;
	my $port = shift;
	print "Connecting ($host:$port)... ";
	$$r_socket = IO::Socket::INET->new(
			PeerAddr	=> $host,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout		=> 4);
	($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? print "connected\n" : print "couldn't connect\n";
}

sub dataWaiting {
	my $r_fh = shift;
	my $bits;
	vec($bits,fileno($$r_fh),1)=1;
	return (select($bits,$bits,$bits,0.05) > 1);
}

sub input_client {
	my ($input, $switch);
	my $msg;
	my $local_socket;
	my ($addrcheck, $portcheck, $hostcheck);
	print "Spawning Input Socket... ";
	my $pid = fork;
	if ($pid == 0) {
		$local_socket = IO::Socket::INET->new(
				PeerAddr	=> $config{'local_host'},
				PeerPort	=> $config{'local_port'},
				Proto		=> 'tcp',
				Timeout		=> 4);
		($local_socket) || die "Error creating connection to local server: $!";
		while (1) {
			$input = <STDIN>;
			chomp $input;
			($switch) = $input =~ /^(\w*)/;
			if ($input ne "") {
				$local_socket->send($input);
			}
			last if ($input eq "quit");
		}
		close($local_socket);
		exit;
	} else {
		$input_socket = $server_socket->accept();
		(inet_aton($input_socket->peerhost()) == inet_aton($config{'local_host'})) 
		|| die "Input Socket must be connected from localhost";
		print "connected\n";
		return $pid;
	}
}

sub killConnection {
	my $r_socket = shift;
	if ($$r_socket && $$r_socket->connected()) {
		print "Disconnecting (".$$r_socket->peerhost().":".$$r_socket->peerport().")... ";
		close($$r_socket);
		!$$r_socket->connected() ? print "disconnected\n" : print "couldn't disconnect\n";
	}
}

#######################################
#######################################
#FILE PARSING AND WRITING
#######################################
#######################################

sub addParseFiles {
	my $file = shift;
	my $hash = shift;
	my $function = shift;
	$parseFiles[$parseFiles]{'file'} = $file;
	$parseFiles[$parseFiles]{'hash'} = $hash;
	$parseFiles[$parseFiles]{'function'} = $function;
	$parseFiles++;
}

sub chatLog {
	$type = shift;
	$message = shift;
#mod Start
# Seperate ChatLog
	alertsound($config{'alertSound_name'},$config{'alertSound_volume'}) if ($config{'alertSound'} && ($type eq "D" || $type eq "s"));
	if ( $type eq "s") {
		open CHAT, ">> logs\/$config{'username'}_GMMessage.txt";
	} elsif ( $type eq "i") {
		open CHAT, ">> logs\/$config{'username'}_GetItem.txt";
	} elsif ( $type eq "shop") {
		open CHAT, ">> logs\/$config{'username'}_Shoplog.txt";
	} else {
		open CHAT, ">> logs\/$config{'username'}_Chat.txt";
	}
#mod Stop
	print CHAT "[".getFormattedDate(int(time))."][".uc($type)."] $message";
	close CHAT;
}

sub chatLog_clear { 
	if (-e "logs\/$config{'username'}_GMMessage.txt") { unlink("logs\/$config{'username'}_GMMessage.txt"); }
	if (-e "logs\/$config{'username'}_GetItem.txt") { unlink("logs\/$config{'username'}_GetItem.txt"); }
	if (-e "logs\/$config{'username'}_Chat.txt") { unlink("logs\/$config{'username'}_Chat.txt"); }
	if (-e "logs\/$config{'username'}_Storage.txt") { unlink("logs\/$config{'username'}_Storage.txt"); }
	if (-e "logs\/$config{'username'}_DUMP.txt") { unlink("logs\/$config{'username'}_DUMP.txt"); }
	if (-e "logs\/$config{'username'}_Tmpmr.txt") { unlink("logs\/$config{'username'}_Tmpmr.txt"); }
}


sub convertGatField {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	open FILE, "+> $file";
	binmode(FILE);
	print FILE pack("S*", $$r_hash{'width'}, $$r_hash{'height'});
	for ($i = 0; $i < @{$$r_hash{'field'}}; $i++) {
		print FILE pack("C1", $$r_hash{'field'}[$i]);
	}
	close FILE;
}

sub dumpData {
	my $msg = shift;
	my $dump;
	my $i;
	$dump = "\n\n================================================\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\n";
	}
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))."\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg,$i,length($msg) - $i))."\n";
	}
	open DUMP, ">> logs\/$config{'username'}_DUMP.txt";
	print DUMP $dump;
	close DUMP;
	print "$dump\n" if $config{'debug'} >= 2;
	print "Message Dumped into DUMP.txt!\n";
}

sub getField {
	my $file = shift;
	my $r_hash = shift;
	my $i, $data;
	undef %{$r_hash};
	if (!(-e $file)) {
		print "\n!!Could not load field - you must install the kore-field pack!!\n\n";
	}
	if ($file =~ /\//) {
		($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
	} else {
		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	}
	open FILE, $file;
	binmode(FILE);
	read(FILE, $data, 4);
	my $width = unpack("S1", substr($data, 0,2));
	my $height = unpack("S1", substr($data, 2,2));
	$$r_hash{'width'} = $width;
	$$r_hash{'height'} = $height;
	while (read(FILE, $data, 1)) {
		$$r_hash{'field'}[$i] = unpack("C",$data);
		$$r_hash{'rawMap'} .= $data;
		$i++;
	}
	close FILE;
}

sub getGatField {
	my $file = shift;
	my $r_hash = shift;
	my $i, $data;
	undef %{$r_hash};
	($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	open FILE, $file;
	binmode(FILE);
	read(FILE, $data, 16);
	my $width = unpack("L1", substr($data, 6,4));
	my $height = unpack("L1", substr($data, 10,4));
	$$r_hash{'width'} = $width;
	$$r_hash{'height'} = $height;
	while (read(FILE, $data, 20)) {
		$$r_hash{'field'}[$i] = unpack("C1", substr($data, 14,1));
		$i++;
	}
	close FILE;
}

sub getResponse {
	my $type = shift;
	my $key;
	my @keys;
	my $msg;
	foreach $key (keys %responses) {
		if ($key =~ /^$type\_\d+$/) {
			push @keys, $key;
		} 
	}
	$msg = $responses{$keys[int(rand(@keys))]};
	$msg =~ s/\%\$(\w+)/$responseVars{$1}/eig;
	return $msg;
}

sub load {
	my $r_array = shift;
	
	foreach (@{$r_array}) {
		if (-e $$_{'file'}) {
			print "Loading $$_{'file'}...\n";
		} else {
			print "Error: Couldn't load $$_{'file'}\n";
		}
		&{$$_{'function'}}("$$_{'file'}", $$_{'hash'});
	}
}



sub parseDataFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close FILE;
}

sub parseDataFile_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{lc($key)} = $value;
		}
	}
	close FILE;
}

sub parseDataFile2 {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		$key =~ s/\s//g;
		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}
		if ($key ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close FILE;
}

sub parseItemsControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,@args;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
		@args = split / /,$args;
		if ($key ne "") {
			$$r_hash{lc($key)}{'keep'} = $args[0];
			$$r_hash{lc($key)}{'storage'} = $args[1];
			$$r_hash{lc($key)}{'sell'} = $args[2];
		}
	}
	close FILE;
}

sub parseNPCs {
	my $file = shift;
	my $r_hash = shift;
	my $i, $string;
	undef %{$r_hash};
	my $key,$value;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args > 4) {
			$$r_hash{$args[0]}{'map'} = $args[1];
			$$r_hash{$args[0]}{'pos'}{'x'} = $args[2];
			$$r_hash{$args[0]}{'pos'}{'y'} = $args[3];
			$string = $args[4];
			for ($i = 5; $i < @args; $i++) {
				$string .= " $args[$i]";
			}
			$$r_hash{$args[0]}{'name'} = $string;
		}
	}
	close FILE;
}

sub parseMonControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,@args;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]+?)\t(\d+[\s\S]*)/;
		@args = split / /,$args;
		if ($key ne "") {
			$$r_hash{lc($key)}{'attack_auto'} = $args[0];
			$$r_hash{lc($key)}{'teleport_auto'} = $args[1];
			$$r_hash{lc($key)}{'teleport_search'} = $args[2];
		}
	}
	close FILE;
}

sub parsePortals {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value;
	my %IDs;
	my $i;
	my $j = 0;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args > 5) {
			$IDs{$args[0]}{$args[1]}{$args[2]} = "$args[0] $args[1] $args[2]";
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'ID'} = "$args[0] $args[1] $args[2]";
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'map'} = $args[0];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'x'} = $args[1];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'y'} = $args[2];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'map'} = $args[3];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'x'} = $args[4];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'y'} = $args[5];
			if ($args[6] ne "") {
				$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'ID'} = $args[6];
				for ($i = 7; $i < @args; $i++) {
					$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}[@{$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}}] = $args[$i];
				}
			}
		}
		$j++;
	}
	foreach (keys %{$r_hash}) {
		$$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
	}
	close FILE;
}

sub parsePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args) {
			$map = shift @args;
			$x = shift @args;
			$y = shift @args;
			for ($i = 0; $i < @args; $i += 4) {
				$$r_hash{"$map $x $y"}{"$args[$i] $args[$i+1] $args[$i+2]"} = $args[$i+3];
			}
		}
	}
	close FILE;
}

sub parseReload {
	my $temp = shift;
	my @temp;
	my %temp;
	my $temp2;
	my $except;
	my $found;
	while ($temp =~ /(\w+)/g) {
		$temp2 = $1;
		$qm = quotemeta $temp2;
		if ($temp2 eq "all") {
			foreach (@parseFiles) {
				$temp{$$_{'file'}} = $_;
			}
		} elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
			$except = 1;
		} else {
			if ($except) {
				foreach (@parseFiles) {
					delete $temp{$$_{'file'}} if $$_{'file'} =~ /$qm/i;
				}
			} else {
				foreach (@parseFiles) {
					$temp{$$_{'file'}} = $_ if $$_{'file'} =~ /$qm/i;
				}
			}
		}
	}
	foreach $temp (keys %temp) {
		$temp[@temp] = $temp{$temp};
	}
	load(\@temp);
}

sub parseResponses {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value;
	my $i;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		if ($key ne "" && $value ne "") {
			$i = 0;
			while ($$r_hash{"$key\_$i"} ne "") {
				$i++;
			}
			$$r_hash{"$key\_$i"} = $value;
		}
	}
	close FILE;
}

sub parseROLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	open FILE, $file;
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
	}
	close FILE;
}

sub parseSkillsLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
		$i++;
	}
	close FILE;
}


sub parseSkillsIDLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$i} = $stuff[1];
		}
		$i++;
	}
	close FILE;
}

sub parseSkillsReverseLUT_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{lc($stuff[1])} = $stuff[0];
		}
		$i++;
	}
	close FILE;
}

sub parseSkillsSPLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	my $i;
	$i = 1;
	open FILE, $file;
	foreach (<FILE>) {
		if (/^\@/) {
			undef $ID;
			$i = 1;
		} elsif (!$ID) {
			($ID) = /([\s\S]+)#/;
		} else {
			($$r_hash{$ID}{$i++}) = /(\d+)#/;
		}
	}
	close FILE;
}

sub parseTimeouts {
	my $file = shift;
	my $r_hash = shift;
	my $key,$value;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key}{'timeout'} = $value;
		}
	}
	close FILE;
}

sub writeDataFile {
	my $file = shift;
	my $r_hash = shift;
	my $key,$value;
	open FILE, "+> $file";
	foreach (keys %{$r_hash}) {
		if ($_ ne "") {
			print FILE "$_ $$r_hash{$_}\n";
		}
	}
	close FILE;
}

sub writeDataFileIntact {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open FILE, $file;
	foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}\n";
        }
	close FILE;
	open FILE, "+> $file";
	print FILE $data;
	close FILE;
}

sub writeDataFileIntact2 {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open FILE, $file;
	foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}{'timeout'}\n";
        }
	close FILE;
	open FILE, "+> $file";
	print FILE $data;
	close FILE;
}

sub writePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	open FILE, "+> $file";
	foreach $key (keys %{$r_hash}) {
		next if (!(keys %{$$r_hash{$key}}));
		print FILE $key;
		foreach (keys %{$$r_hash{$key}}) {
			print FILE " $_ $$r_hash{$key}{$_}";
		}
		print FILE "\n";
	}
	close FILE;
}

sub updateMonsterLUT {
	my $file = shift;
	my $ID = shift;
	my $name = shift;
	open FILE, ">> $file";
	print FILE "$ID $name\n";
	close FILE;
}

sub updatePortalLUT {
	my ($file, $src, $x1, $y1, $dest, $x2, $y2) = @_;
	open FILE, ">> $file";
	print FILE "$src $x1 $y1 $dest $x2 $y2\n";
	close FILE;
}

sub updateNPCLUT {
	my ($file, $ID, $map, $x, $y, $name) = @_;
	open FILE, ">> $file"; 
	print FILE "$ID $map $x $y $name\n"; 
	close FILE; 
} 

#######################################
#######################################
#HASH/ARRAY MANAGEMENT
#######################################
#######################################


sub binAdd {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i <= @{$r_array};$i++) {
		if ($$r_array[$i] eq "") {
			$$r_array[$i] = $ID;
			return $i;
		}
	}
}

sub binFind {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binFindReverse {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = @{$r_array} - 1; $i >= 0;$i--) {
		if ($$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binRemove {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			undef $$r_array[$i];
			last;
		}
	}
}

sub binRemoveAndShift {
	my $r_array = shift;
	my $ID = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne $ID || $found ne "") {
			push @newArray, $$r_array[$i];
		} else {
			$found = $i;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binRemoveAndShiftByIndex {
	my $r_array = shift;
	my $index = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($i != $index) {
			push @newArray, $$r_array[$i];
		} else {
			$found = 1;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binSize {
	my $r_array = shift;
	my $found = 0;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne "") {
			$found++;
		}
	}
	return $found;
}

sub existsInList {
	my ($list, $val) = @_;
	@array = split /,/, $list;
	return 0 if ($val eq "");
	$val = lc($val);
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");
		return 1 if (lc($_) eq $val);
	}
	return 0;
}

sub findIndex {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} == $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} eq $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID))
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findKey {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} == $ID) {
			return $_;
		}
	}
}

sub findKeyString {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} eq $ID) {
			return $_;
		}
	}
}

sub minHeapAdd {
	my $r_array = shift;
	my $r_hash = shift;
	my $match = shift;
	my $i;
	my $found;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (!$found && $$r_hash{$match} < $$r_array[$i]{$match}) {
			push @newArray, $r_hash;
			$found = 1;
		}
		push @newArray, $$r_array[$i];
	}
	if (!$found) {
		push @newArray, $r_hash;
	}
	@{$r_array} = @newArray;
}

sub updateDamageTables {
	my ($ID1, $ID2, $damage) = @_;
	if ($ID1 eq $accountID) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromYou'}++;
			}
		}
	} elsif ($ID2 eq $accountID) {
		if (%{$monsters{$ID1}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedYou'}++;
			}
			$monsters{$ID1}{'attackedByPlayer'} = 0;
			$monsters{$ID1}{'attackedYou'}++ unless ($monsters{$ID1}{'dmgFromPlayer'} || $monsters{$ID1}{'missedFromPlayer'} || $monsters{$ID1}{'missedToPlayer'} || $monsters{$ID1}{'dmgToPlayer'});
		}
	} elsif (%{$monsters{$ID1}}) {
		if (%{$players{$ID2}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToPlayer'}{$ID2} += $damage;
			$players{$ID2}{'dmgFromMonster'}{$ID1} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedToPlayer'}{$ID2}++;
				$players{$ID2}{'missedFromMonster'}{$ID1}++;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID2}}) {
				$monsters{$ID1}{'dmgToParty'} += $damage;
				$monsters{$ID1}{'attackedByPlayer'} = 0 if ($config{'attackAuto_party'} || ( 
				$config{'attackAuto_followTarget'} && 
				$config{'follow'} && $players{$ID2}{'name'} eq $config{'followTarget'})); 
			} else { 
				$monsters{$ID1}{'attackedByPlayer'} = 1 unless ($config{'attackAuto_followTarget'} && 
				$config{'follow'} && $players{$ID2}{'name'} eq $config{'followTarget'});
			}
		}
		
	} elsif (%{$players{$ID1}}) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromPlayer'}{$ID1} += $damage;
			$players{$ID1}{'dmgToMonster'}{$ID2} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromPlayer'}{$ID1}++;
				$players{$ID1}{'missedToMonster'}{$ID2}++;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID1}}) {
				$monsters{$ID2}{'dmgFromParty'} += $damage;
			}
		}
	}
}


#######################################
#######################################
#MISC FUNCTIONS
#######################################
#######################################

sub compilePortals {
	undef %mapPortals;
	foreach (keys %portals_lut) {
		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	$l = 0;
	foreach $map (keys %mapPortals) {
		foreach $portal (keys %{$mapPortals{$map}}) {
			foreach (keys %{$mapPortals{$map}}) {
				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					if ($field{'name'} ne $map) {
						print "Processing map $map\n";
						getField("fields/$map.fld", \%field);
					}
					print "Calculating portal route $portal -> $_\n";
					ai_route_getRoute(\@solution, \%field, \%{$mapPortals{$map}{$portal}{'pos'}}, \%{$mapPortals{$map}{$_}{'pos'}});
					compilePortals_getRoute();
					$portals_los{$portal}{$_} = (@solution) ? 1 : 0;
				}
			}
		}
	}

	writePortalsLOS("$def_table/portalsLOS.txt", \%portals_los);

	print "Wrote portals Line of Sight table to '$def_table/portalsLOS.txt'\n";

}

sub compilePortals_check {
	my $r_return = shift;
	my %mapPortals;
	undef $$r_return;
	foreach (keys %portals_lut) {
		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	foreach $map (keys %mapPortals) {
		foreach $portal (keys %{$mapPortals{$map}}) {
			foreach (keys %{$mapPortals{$map}}) {
				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					$$r_return = 1;
					return;
				}
			}
		}
	}
}

sub compilePortals_getRoute {	
	if ($ai_seq[0] eq "route_getRoute") {
		if (!$ai_seq_args[0]{'init'}) {
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			$ai_seq_args[0]{'timeout'} = 90000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;
	}
}


sub getCoordString {
	my $x = shift;
	my $y = shift;
	return pack("C*", int($x / 4), ($x % 4) * 64 + int($y / 16), ($y % 16) * 16);
}

sub getFormattedDate {
        my $thetime = shift;
        my $r_date = shift;
        my @localtime = localtime $thetime;
        my $themonth = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)[$localtime[4]];
        $localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
        $localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
        $localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
        $$r_date = "$themonth $localtime[3] ,".($localtime[5] + 1900)."  $localtime[2]:$localtime[1]:$localtime[0]";
        return $$r_date;
}

sub getHex {
	my $data = shift;
	my $i;
	my $return;
	for ($i = 0; $i < length($data); $i++) {
		$return .= uc(unpack("H2",substr($data, $i, 1)));
		if ($i + 1 < length($data)) {
			$return .= " ";
		}
	}
	return $return;
}



sub getTickCount {
	my $time = int(time()*1000);
	if (length($time) > 9) {
		return substr($time, length($time) - 8, length($time));
	} else {
		return $time;
	}
}

sub makeCoords {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = unpack("C", substr($rawCoords, 0, 1)) * 4 + (unpack("C", substr($rawCoords, 1, 1)) & 0xC0) / 64;
	$$r_hash{'y'} = (unpack("C",substr($rawCoords, 1, 1)) & 0x3F) * 16 + 
				(unpack("C",substr($rawCoords, 2, 1)) & 0xF0) / 16;
}
sub makeCoords2 {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = (unpack("C",substr($rawCoords, 1, 1)) & 0xFC) / 4 + 
				(unpack("C",substr($rawCoords, 0, 1)) & 0x0F) * 64;
	$$r_hash{'y'} = (unpack("C", substr($rawCoords, 1, 1)) & 0x03) * 256 + unpack("C", substr($rawCoords, 2, 1));
}
sub makeIP {
	my $raw = shift;
	my $ret;
	my $i;
	for ($i=0;$i < 4;$i++) {
		$ret .= hex(getHex(substr($raw, $i, 1)));
		if ($i + 1 < 4) {
			$ret .= ".";
		}
	}
	return $ret;
}

sub portalExists {
	my ($map, $r_pos) = @_;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $map && $portals_lut{$_}{'source'}{'pos'}{'x'} == $$r_pos{'x'}
			&& $portals_lut{$_}{'source'}{'pos'}{'y'} == $$r_pos{'y'}) {
			return $_;
		}
	}
}

sub timeOut {
	my ($r_time, $compare_time) = @_;
	if ($compare_time ne "") {
		return (time - $r_time > $compare_time);
	} else {
		return (time - $$r_time{'time'} > $$r_time{'timeout'});
	}
}

sub vocalString {
        my $letter_length = shift;
        return if ($letter_length <= 0);
        my $r_string = shift;
        my $test;
        my $i;
        my $password;
        my @cons = ("b", "c", "d", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y", "z", "tr", "cl", "cr", "br", "fr", "th", "dr", "ch", "st", "sp", "sw", "pr", "sh", "gr", "tw", "wr", "ck");
        my @vowels = ("a", "e", "i", "o", "u" , "a", "e" ,"i","o","u","a","e","i","o", "ea" , "ou" , "ie" , "ai" , "ee" ,"au", "oo");
        my %badend = ( "tr" => 1, "cr" => 1, "br" => 1, "fr" => 1, "dr" => 1, "sp" => 1, "sw" => 1, "pr" =>1, "gr" => 1, "tw" => 1, "wr" => 1, "cl" => 1);
        for (;;) {
                $password = "";
                for($i = 0; $i < $letter_length; $i++){
                        $password .= $cons[rand(@cons - 1)] . $vowels[rand(@vowels - 1)];
                }
                $password = substr($password, 0, $letter_length);
                ($test) = ($password =~ /(..)\z/);
                last if ($badend{$test} != 1);
        }
        $$r_string = $password;
        return $$r_string;
}

#---------------------------------------------- Mod Add-On --------------------------------------------------------------------------------------------#

# Guild Member Name Request
sub sendNameRequest { 
	my $r_socket = shift; 
	my $ID = shift; 
	my $msg = pack("C*", 0x93, 0x01) . $ID; 
	encrypt($r_socket, $msg); 
	print "Sent Name Request : ".getHex($ID)."\n" if ($config{'debug'} >= 2); 
}

# Weapon Name Modifier
sub modifingName { 
	my $r_hash = shift;
	my $modified = ""; 
	my @card; 
	my $prefix="";
	my $postfix=""; 
	my ($i, $j, $k); 
	
	if (!$$r_hash{'type_equip'} && (!$$r_hash{'elements'} && !$$r_hash{'refined'} && !$$r_hash{'card'}[0] && !$$r_hash{'star'})) { 
		return 0;
	} else {
		$modified = "[+$$r_hash{'refined'}]" if ($$r_hash{'refined'});
		if ($$r_hash{'star'}==1){
			$modified .="[V Strong]";
		}elsif ($$r_hash{'star'}==2){
			$modified .="[VV Strong]";
		}elsif ($$r_hash{'star'}==3){
			$modified .="[VVV Strong]";
		}
		$modified .="[".$elements_lut{$$r_hash{'elements'}}."]" if ($$r_hash{'elements'});

		for ($i = 0; $i < 4; $i++) {
			last if !$$r_hash{'card'}[$i];
			if (@card) { 
				for ($j = 0; $j <= @card; $j++) { 
					if ($card[$j]{'ID'} eq $$r_hash{'card'}[$i]) { 
						$card[$j]{'amount'}++; 
						last; 
					} elsif ($card[$j]{'ID'} eq "") { 
						$card[$j]{'ID'} = $$r_hash{'card'}[$i]; 
						$card[$j]{'amount'} = 1; 
						last; 
					}
				}
			}else{
				$card[0]{'ID'} = $$r_hash{'card'}[$i]; 
				$card[0]{'amount'} = 1; 
			}
		}
		if (@card) {
			for ($i = 0; $i < @card; $i++) { 
				if (($cards_lut{$card[$i]{'ID'}} =~/^of*/)||($cards_lut{$card[$i]{'ID'}} eq "Under a Cast")) { 
					if ($card[$i]{'amount'} == 1) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}}";
					} elsif ($card[$i]{'amount'} == 2) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}} Double";
					} elsif ($card[$i]{'amount'} == 3) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}} Triple";
					} elsif ($card[$i]{'amount'} == 4) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}} Quadraple";
					}
				} else {
					if ($card[$i]{'amount'} == 1) {
						$prefix .= "$cards_lut{$card[$i]{'ID'}} "; 
					} elsif ($card[$i]{'amount'} == 2) { 
						$prefix .= "Double $cards_lut{$card[$i]{'ID'}} "; 
					} elsif ($card[$i]{'amount'} == 3) { 
						$prefix .= "Triple $cards_lut{$card[$i]{'ID'}} "; 
					} elsif ($card[$i]{'amount'} == 4) { 
						$prefix .= "Quadraple $cards_lut{$card[$i]{'ID'}} "; 
					}
				}
			}
		}
		$$r_hash{'name'} = $modified.$prefix.$$r_hash{'name'}.$postfix;
	}
}

# ChatAuto Function
sub getResMsg {
	my $key = shift;
	my @keys;
	my $msg,$word;
	foreach $key1 (keys %qmsg) {
		if(($key =~ /^\/[\w+]/ && $key =~ /$key1/)||($key =~ /$key1/ && !($key1 =~ /^\/[\w+]/))){
			push @keys,$key1;
		}
	}
	if (scalar(@keys)!=0) {
		$word = $keys[int(rand(@keys))];
		$msg = $qmsg{'/ans'}{$qmsg{$word}}[int(rand(scalar(@{$qmsg{'/ans'}{$qmsg{$word}}})))];
	}
	$msg =~ s/\%\$(\w+)/$chars[$config{'char'}]{$1}/eig;
	return $msg;
}

# Parse Chatauto.txt
sub parseChatMsg {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value,$j;
	open FILE, $file;
	$i=0;
	foreach(<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]*)\t([\s\S]*)/;
		if ($key ne "") {
				$key =~ s/_/ /g;
				@data = split /,/,$key;
				@args = split /,/,$args;
				push @{ $$r_hash{'/ans'}{$i} },@args;
				foreach $keys (@data) {
					$$r_hash{$keys} = $i;
				}
				$i++;
		}
	}
	close FILE;
}

# Pet Command
sub sendPetCommand{
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xA1, 0x01).pack("C1",$flag);
	encrypt($r_socket, $msg);
	print "Sent Pet Command : $flag\n" if ($config{'debug'});
}

# Secure Login
sub sendMasterSecureLogin{
	my $r_socket = shift;
	my $username = shift;
	my $password = shift; 
	my $salt = shift;
	if ($config{'SecureLogin'} == 1) {
		$salt = $salt . $password;
	} else {
		$salt = $password . $salt;
	}
	my $msg = pack("C*", 0xDD, 0x01) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
					 md5($salt) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt($r_socket, $msg);
}

sub sendMasterEncryptKeyRequest{
	my $r_socket = shift;
	my $msg = pack("C*", 0xDB, 0x01);
	encrypt($r_socket, $msg);
}

# Stuck Killer
sub ClearRouteAI {
	my $msg = shift;
	print $msg;
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	ai_clientSuspend(0, 5);
}

sub Unstuck {
	my $msg = shift;
	$totalStuckCount++;
	$old_x = 0;
	$old_y = 0;
	$old_pos_x = 0;
	$old_pos_y = 0;
	$move_x = 0;
	$move_y = 0;
	$move_pos_x = 0;
	$move_pos_y = 0;
	print $msg;
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	if($totalStuckCount >= 6) { useTeleport(1); }
	print "AI route Unstuck over $totalStuckCount times ,Teleport\n";
	useTeleport(1);
	ai_clientSuspend(0, 5);
}

sub RespawnUnstuck {
	$totalStuckCount = 0;
	$calcTo_SameSpot = 0;
	$calcFrom_SameSpot = 0;
	$moveTo_SameSpot = 0;
	$moveFrom_SameSpot = 0;
	$old_x = 0;
	$old_y = 0;
	$old_pos_x = 0;
	$old_pos_y = 0;
	$move_x = 0;
	$move_y = 0;
	$move_pos_x = 0;
	$move_pos_y = 0;
	print "Cannot calculate route, respawning to saveMap ...\n";
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	if($totalStuckCount >= 6) { useTeleport(2); }
	ai_clientSuspend(0, 5);
}

#parse Ppl function
sub parsePplControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,@args;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]+?)\t(\d+[\s\S]*)/;
		@args = split / /,$args;
		if ($key ne "") {
			$$r_hash{$key}{'ignored_auto'} = $args[0];
			$$r_hash{$key}{'teleport_auto'} = $args[1];
			$$r_hash{$key}{'disconnect_auto'} = $args[2];
		}
	}
	close FILE;
}

#auto generated ppl avoid
sub updatepplControl {
	my $file = shift;
	my $name = shift;
	my $ID = shift;
	open FILE, ">> $file";
	print FILE "#$ID\n$name\t$config{'ppl_defaultFlag'}\n";
	close FILE;
}

sub alertsound {
	my $wav = shift;
	my $vol = shift;
	Win32::Sound::Volume($vol.'%');
	Win32::Sound::Play($wav);
	Win32::Sound::Stop();
}

sub sendEnteringVender {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x30, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Entering Vender: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendBuyVender {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x34, 0x01, 0x0C, 0x00) . $venderID . pack("S*", $amount, $ID);
	encrypt($r_socket, $msg);
	print "Sent Vender Buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub findIndexString_lc_not_equip {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID) && !($$r_array[$i]{'equipped'}))
			 || (!%{$$r_array[$i]} && $ID eq "")) {			  
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub modifiedWalk{
	my $type = shift;
	my ($x,$y);
	my ($key,$distX,$distY);
	my ($oldX,$oldY)=($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'},$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}); 
	if ($type==1) {
		return if(binSize(\@portalsID)); 
		return if(binFind(\@ai_seq, "attack")); 
		for ($i = -1; $i < 2; $i++) { 
			for ($j = -1; $j < 2; $j++) {
				next if ($i == 0 && $j == 0); 
				return if(checkCoordinate($oldX,$oldY,$j,$i)==1); 
			} 
		} 
	}elsif ($type==2){
		return if(binSize(\@portalsID));
		for ($j = -1; $j < 2; $j++) { 
			next if ($j == 0); 
			return if(checkCoordinate($oldX,$oldY,$j,0)==1); 
		} 
		for ($i = -1; $i < 2; $i++) { 
			next if ($i == 0); 
			return if(checkCoordinate($oldX,$oldY,0,$i)==1); 
		} 
		for ($i = -1; $i < 2; $i++) { 
			for ($j = -1; $j < 2; $j++) { 
				next if ($i == 0 || $j == 0); 
				return if(checkCoordinate($oldX,$oldY,$j,$i)==1); 
			}
		}
	}else{
		return if(binSize(\@portalsID));
		return if (binFind(\@ai_seq, "attack"));
		for ($i = -1; $i < 2; $i++) {
			for ($j = -1; $j < 2; $j++) {
				next if ($i == 0 && $j == 0);
				$key=$key.$field{'field'}[($i+$oldY)*$field{'width'}+$oldX + $j];
			}
		}
		return if(!$modifiedWalk{$key});
		($x,$y)=(-1,-1) if($modifiedWalk{$key}==1);
		($x,$y)=(0,-1) if($modifiedWalk{$key}==2);
		($x,$y)=(1,-1) if($modifiedWalk{$key}==3);
		($x,$y)=(-1,0) if($modifiedWalk{$key}==4);
		($x,$y)=(0,0) if($modifiedWalk{$key}==5);
		($x,$y)=(1,0) if($modifiedWalk{$key}==6);
		($x,$y)=(-1,1) if($modifiedWalk{$key}==7);
		($x,$y)=(0,1) if($modifiedWalk{$key}==8);
		($x,$y)=(1,1) if($modifiedWalk{$key}==9);
		return if($modifiedWalk{$key}==5);
		$distX=$x*$config{'modifiedWalkDistance'};
		$distY=$y*$config{'modifiedWalkDistance'};
		while($distX || $distY){
			($x,$y)=($distX+$oldX,$distY+$oldY);
			if( $field{'field'}[$y*$field{'width'}+$x]==0 ){
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}=$x;
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}=$y;
				last;
			}
			if($distX){
				$distX--;
			}elsif($distX<0){
				$dist++;
			}
			if($distY){
				$distY--;
			}elsif($distY<0){
				$distY++;
			}
		}
	}
} 

sub checkCoordinate{ 
	my ($oldX,$oldY,$j,$i)=@_; 
	my ($x,$y); 
	if( $field{'field'}[$oldY*$field{'width'}+$oldX + $j]==1 ){ 
		$x=$j*-1*$config{'modifiedWalkDistance'}+$oldX; 
		$y=$i*-1*$config{'modifiedWalkDistance'}+$oldY; 
		if( $field{'field'}[$y*$field{'width'}+$x]==0 ){ 
			$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}=$x; 
			$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}=$y; 
			return 1; 
		}
	} 
	return 0; 
}

sub CheckStorageNPC{ 
	my ($IDOld, $mapOld,%posOld); 
	my %pos=%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}; 
	foreach (@npcsID) { 
		next if (!$_); 
		if($npcs_lut{$config{'storageAuto_npc'}}{'map'} eq $field{'name'} 
			&& $pos{'x'}==$npcs{$_}{'pos'}{'x'} 
			&& $pos{'y'}==$npcs{$_}{'pos'}{'y'} && $npcs{$_}{'nameID'} ne $config{'storageAuto_npc'}){ 
			$IDOld= $npcs{$_}{'nameID'}; 
			$mapOld = $npcs_lut{$npcs{$_}{'nameID'}}{'map'}; 
			%posOld = %{$npcs_lut{$npcs{$_}{'nameID'}}{'pos'}}; 
			$npcs_lut{$npcs{$_}{'nameID'}}{'name'}=($npcs{$_}{'name'} ne "") ? $npcs{$_}{'name'} : "Kafra"; 
			$npcs_lut{$npcs{$_}{'nameID'}}{'map'}=$field{'name'}; 
			%{$npcs_lut{$npcs{$_}{'nameID'}}{'pos'}}=%{$npcs{$_}{'pos'}}; 
			WriteNPCLUT($IDOld,$mapOld,%posOld,$npcs_lut{$npcs{$_}{'nameID'}}{'name'}); 
			configModify("storageAuto_npc", $npcs{$_}{'nameID'}); 
			print "**Auto-Update StorageAuto NPC ID\n";
			chatLog("C", "**Auto-Update StorageAuto NPC ID\n"); 
			last; 
		} 
	}
}

sub WriteNPCLUT { 
	my $file="$def_table/npcs.txt";
	my ($IDOld,$mapOld,%posOLD,$nameOld) = @_; 
	open(FILE,">$file"); 
	foreach (sort keys %npcs_lut) {
		if($_ == $IDOld){ 
			print FILE "$IDOld $mapOld $posOLD{'x'} $posOLD{'y'} $nameOld\n"; 
		}else{
			print FILE "$_ $npcs_lut{$_}{'map'} $npcs_lut{$_}{'pos'}{'x'} $npcs_lut{$_}{'pos'}{'y'} $npcs_lut{$_}{'name'}\n"; 
		} 
	} 
	close FILE; 
}

sub sendGuildInfoRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0x4d, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Guild Information Request\n" if ($config{'debug'});
}

sub sendGuildRequest {
	my $r_socket = shift;
	my $page = shift;
	my $msg = pack("C*", 0x4f, 0x01).pack("L1", $page);
	encrypt($r_socket, $msg);
	print "Sent Guild Request Page : ".$page."\n" if ($config{'debug'});
}

sub sendGuildJoin{
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x6B, 0x01).$ID.pack("L1", $flag);
	encrypt($r_socket, $msg);
	print "Sent Join Guild : ".getHex($ID).", $flag\n" if ($config{'debug'});
}

sub sendGuildAlly{
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x72, 0x01).$ID.pack("L1", $flag);
	encrypt($r_socket, $msg);
	print "Sent Ally Guild : ".getHex($ID).", $flag\n" if ($config{'debug'});
}

sub parseDataFile3 {
	my $file = shift;
	my $r_hash = shift;
	my $ID;
	undef %{$r_hash};
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/\r//g;
		s/\n//g;
		if( $_ ne "" ){
			$ID = pack("L1",$_);
			$$r_hash{$ID} = 1;
		}
	}
	close FILE;
}

sub closeShop {
	my $r_socket = shift;
	my $msg = pack("C*", 0x2E, 0x01);
	encrypt($r_socket, $msg);
	print "Closing Your Shop \n";
	$ai_v{'temp'}{'shopOpen'} = 0;
	if ($ai_seq[0] eq "shopauto") {
		shift @ai_seq;
		shift @ai_seq_args;
	}
}

sub openShop {
	my $r_socket = shift;
	my ($i,$index,$totalitem,$items_selling,$citem,$oldid);
	my %itemtosell;
	if($chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} && $shop{'shop_title'} ne ""){
		$i=0;
		$items_selling=0;
		while ($shop{"name_$i"} ne "" && $items_selling < $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}+2) {
			for ($index=0; $index< @cartID; $index++) {
				if ($cart{'inventory'}{$cartID[$index]}{'name'} eq $shop{"name_$i"}) {
					$citem = $index;
					foreach (keys %itemtosell) {
						if ($_ eq $index) {
							$oldid = $_;
							$citem = -1;
						}
					}
					if ($citem>-1) {
						$itemtosell{$index}{'index'} = $cart{'inventory'}{$cartID[$index]}{'index'};
						#amount calculate
						if ($shop{"quantity_$i"}>0 && $cart{'inventory'}{$cartID[$index]}{'amount'} >= $shop{"quantity_$i"}) {
							$itemtosell{$index}{'amount'} = $shop{"quantity_$i"};
						}elsif ($shop{"quantity_$i"}>0 && $cart{'inventory'}{$cartID[$index]}{'amount'} < $shop{"quantity_$i"}){
							$itemtosell{$index}{'amount'} = $cart{'inventory'}{$cartID[$index]}{'amount'};
						}else{
							$itemtosell{$index}{'amount'} = 1;
						}
						#price calculate
						if ($shop{"price_$i"}>10000000){
							$itemtosell{$index}{'price'} = 10000000;
						}elsif ($shop{"price_$i"}>0){
							$itemtosell{$index}{'price'} = $shop{"price_$i"};
						}else{
							$itemtosell{$index}{'price'} = 1;
						}
						$items_selling++;
						last;
					}
				}
			}
			$i++;
		}

		my $length = 0x55 + 0x08 * $items_selling;

		my $msg = pack("C*", 0xB2, 0x01) . pack("S*", $length) . 
		$shop{'shop_title'} . chr(0) x (80 - length($shop{'shop_title'})) .  pack("C*", 0x01);

		foreach (keys %itemtosell) {
			$msg .= pack("S1",$itemtosell{$_}{'index'}) . pack("S1", $itemtosell{$_}{'amount'}) . pack("L1", $itemtosell{$_}{'price'});
		}
		if( length($msg) == $length ) {
			encrypt($r_socket, $msg);
			print "Openning Your Shop ( $shop{'shop_title'} )\n";
			$ai_v{'temp'}{'shopOpen'} = 1;
		}else{
			print "Error : opening shop...\n";
			shopconfigModify("shop_autoStart",0) if ($shop{'shop_autoStart'});
		}
		if ($ai_seq[0] eq "shopauto") {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}else{
		print "Can not open shop ( no skill to use )\n";
		shopconfigModify("shop_autoStart",0) if ($shop{'shop_autoStart'});
		if ($ai_seq[0] eq "shopauto") {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}
}

sub shopconfigModify {
	my $key = shift;
	my $val = shift;
	print "Shop Config '$key' set to $val\n";
	$shop{$key} = $val;
	writeDataFileIntact("$def_config/shop.txt", \%shop);
}