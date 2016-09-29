#!/usr/bin/perl

# maildir-builder.pl
# Create a mailbox with random messages from a source directory, great for building a test mailbox
# used for performance testing and creating complex data-sets.

# (C) Ben Duncan, Atmail Pty Ltd
# Wed Sep 28 21:41:41 EDT 2016
# Apache License

use Getopt::Long;

my $debug = 0;
my $maildir;
my $output;
my $createdirs;
my $help;
my $count = '1000';
my $randomflag;
my @flags;

# Random flags, more unread probability vs others
push(@flags, "");
push(@flags, "");
push(@flags, "");
push(@flags, "S");
push(@flags, "S");
push(@flags, "FS");
push(@flags, "RS");
push(@flags, "R");
push(@flags, "DS");

# Options via the CLI
GetOptions(	"debug"		=> \$debug,
			"maildir=s"	=> \$maildir,
			"output=s"	=> \$output,
			"createdirs=s" => \$createdirs,
			"help"		=> \$help,
			"count=s"	=> \$count,
			"randomflag" => \$randomflag
			) or die("Undefined args");

if(!$maildir || !$output || $help)	{
	die usage();
}

# Find all files in the source directory, grep for valid messages only, not indexes.
$files = `find $maildir -type f | grep "cur/"`;

# Spit up all the files returned into an array
my @msgs = split("\n", $files);

print "Loaded $maildir, found the following messages:\n";

foreach my $msg (@msgs)	{
	print "=> $msg\n";
}

print "Number of maildir messages available: $#msgs\n\n";

print "Creating $output directory and sub-folders\n";

system("mkdir $output");

my @folders;

# Loop through the root folders
foreach('.', '.Sent', '.Drafts', '.Trash', '.Spam')	{
	push(@folders, $_);
}

# Build a list of sub-dirs
if($createdirs)	{

	for(1 .. $createdirs)	{
		push(@folders, ".Test$_");
	}

}

# Create the maildir structure
foreach my $folder (@folders)	{

	system("mkdir $output/$folder");

	# Create the cur, tmp and new folders, required for a valid maildir directory
	foreach('cur', 'tmp', 'new')	{
		my $sub = $_;
		system("mkdir $output/$folder/$sub");
	}

	print "$output/$folder\n";
}


# Copy the specified number of files, while creating a random filename and flags

print "\nCopying $count messages to $output:\n";

for(1 .. $count)	{
	$newmail = $msgs[rand @msgs];
	$origmail = $newmail;
	$dest = $folders[rand @folders];
	$flag = $flags[rand @flags];

	my $randtime = time() - int(rand(31536000));

	# new maildir timestamp
	$newmail =~ s/cur\/\d+\./cur\/$randtime\./g;

	if( $randomflag )	{
		# random flags
		$newmail =~ s/:2,\w+/:2,$flag/g;
	}

	# Cleanup the new destination filename, we only want the maildir file
	$newmail =~ s/.*?cur\///g;

	# Escape quotes
	$origmail =~ s/"/\\"/g;

	print "$origmail => $output/$dest/cur/$newmail\n";

	system("cp \"$origmail\" '$output/$dest/cur/$newmail'");

}


exit;


#######

sub printDebug()	{
	$message = shift(@_);

	return if(!$debug);

	print $message;
}

sub usage()	{
	print "perl maildir-builder.pl " . " --maildir [/path/to/source/maildir] --output [/path/to/dest/maildir] --help --debug\n\n";

	print "Options:\n";
	print "--createdirs [count]\t\tNumber of Test directories to create\n";
	print "--randomflag\t\tCreate random flags, unseen, read, replied, flag\n";
	print "--count [count]\t\tNumber of messages to randomly copy into the --output directory, default 100.\n\n";

	print "maildir-builder.pl requires a valid source maildir, and a destination directory will be created.\n\n";

	exit;
}

exit;
