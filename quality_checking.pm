package quality_checking;

use strict;
use warnings;

use File::Basename;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(fastQc qualityTrimming);
our @EXPORT = qw();
our $VERSION = 1.1;



sub fastQc{
	my $fqFiles = shift @_;
	my $fastqcOut = shift @_;
	
	print "Running fastqc on files: $fqFiles\n";
	
	if(!-d $fastqcOut){
		mkdir($fastqcOut, 0755) or die "Cannot create directory $fastqcOut: $!";
	}

	system("echo Command: fastqc --outdir $fastqcOut $fqFiles
	fastqc --outdir $fastqcOut $fqFiles");
	
	if($? != 0){
		print STDERR "Error: Failed to execute fastqc on data $fqFiles";
		die;
	}
	else{
		print "Finished: FastQc analysis for data $fqFiles\n\n";
		return 1;
	}
	
}


sub qualityTrimming{
	my $sampleInfo = shift @_;
	my $fastqcOut = shift @_;
	my $cutadaptOut = shift @_;
	
	if(!-d $cutadaptOut){
		mkdir($cutadaptOut, 0755) or die "Cannot create directory $cutadaptOut: $!";
	}
	
	print "Running cutadapt to trim adapter and low quality ends from ",$sampleInfo->{'lib'}," reads\n";
	
	my $cutadaptSE = 'cutadapt --cores 0 -q 20 --nextseq-trim=20 --minimum-length 20';
	my $cutadaptPE = 'cutadapt --cores 0 -q 20 -q 20 --nextseq-trim=20 --nextseq-trim=20 --minimum-length 20 --minimum-length 20';

	my $adapterFwd = '-b XXX ';
	my $adapterRev = '-B XXX ';
	my $pair1File = '';
	my $pair2File = '';
	my $pair1Trimmed = '';
	my $pair2Trimmed = '';
	my $pair1FastqcZip = '';
	my $pair2FastqcZip = '';
	
	my $rerunFastqcFiles = '';
	
	my $isGz = 0;
	if($sampleInfo->{1}=~m/gz$/){
		$isGz=1;
	}
	
	my $illuminaAdapters = '';
	if($sampleInfo->{adapters}){
		if(-e $sampleInfo->{adapters}){
			$illuminaAdapters = join("", ' -a file:',$sampleInfo->{adapters});
		}
	}

	#get adapter sequences reported by FastQc: for read_1
	if($isGz){
		if($sampleInfo->{1} =~ m/([^\/]+).(fastq|fq).gz\s*$/){
			$pair1File = $1;
		}
		else{
			print STDERR "Could not recognize fastq output folder name from file $sampleInfo->{1}\n";
			die;
		}
	}
	else{
		if($sampleInfo->{1} =~ m/([^\/]+).(fastq|fq)\s*$/){
			$pair1File = $1;
		}
		else{
			print STDERR "Could not recognize fastq output folder name from file $sampleInfo->{1}\n";
			die;
		}
	}
	
	print STDERR "R1 prefix: $pair1File\n";
	
	$pair1Trimmed = $cutadaptOut.'/'.$pair1File.".trimmed.fastq.gz";
	$pair1FastqcZip = $pair1File.'_fastqc.zip';
	
	if(-e "$fastqcOut/$pair1FastqcZip"){
		## upzip the FastQC output		
		system("cd $fastqcOut
		unzip -o $pair1FastqcZip");
		
		## get over-represented sequences
		$adapterFwd = &getOverrepresentedSeqs("$fastqcOut/$pair1File\_fastqc/fastqc_data.txt", $adapterFwd);
		print "Adapters to remove from the $sampleInfo->{1} file: ", $adapterFwd,"\n",$illuminaAdapters,"\n";
		
	}
	else{
		print STDERR "Cannot find the FastQC report $fastqcOut/$pair1FastqcZip\n";
		die;
	}
	
	
	#for the read_2
	if($sampleInfo->{'lib'} eq 'PE'){
		
		if($sampleInfo->{adapters}){
			$illuminaAdapters = join("", $illuminaAdapters, ' -A file:',$sampleInfo->{adapters});
		}
		
		#get adapter sequences reported by FastQc: for read_1
		if($isGz){
			if($sampleInfo->{2} =~ m/([^\/]+).(fastq|fq).gz\s*$/){
				$pair2File = $1;
			}
			else{
				print STDERR "Could not recognize fastq output folder name from file $sampleInfo->{2}\n";
				die;
			}
		}
		else{
			if($sampleInfo->{2} =~ m/([^\/]+).(fastq|fq)\s*$/){
				$pair2File = $1;
			}
			else{
				print STDERR "Could not recognize fastq output folder name from file $sampleInfo->{2}\n";
				die;
			}
		}
		
		print STDERR "R2 prefix: $pair2File\n";
				
		$pair2Trimmed = $cutadaptOut.'/'.$pair2File.".trimmed.fastq.gz";
		$pair2FastqcZip = $pair2File.'_fastqc.zip';

		if(-e "$fastqcOut/$pair2FastqcZip"){
			## upzip the FastQC output
			system("cd $fastqcOut
			unzip -o $pair2FastqcZip");
		
			## get over-represented sequences
			$adapterRev = &getOverrepresentedSeqs("$fastqcOut/$pair2File\_fastqc/fastqc_data.txt", $adapterRev);
			
			$adapterRev =~ s/-b/-B/g;
			
			print "Adapters to remove from the $sampleInfo->{2} files: ", $adapterRev,"\n",$illuminaAdapters,"\n";
			
			#Run cutadapt in paired end mode
			system("echo Trimming files $sampleInfo->{1} and $sampleInfo->{2} using paired end mode
			echo Command: $cutadaptPE $adapterFwd $adapterRev $illuminaAdapters -o $pair1Trimmed -p $pair2Trimmed $sampleInfo->{1} $sampleInfo->{2}
			$cutadaptPE $adapterFwd $adapterRev $illuminaAdapters -o $pair1Trimmed -p $pair2Trimmed $sampleInfo->{1} $sampleInfo->{2}");
			
			if($? != 0){
				print STDERR "Cutadapt failed while Trimming files $sampleInfo->{1} and $sampleInfo->{2} using paired end mode\n";
				die;
			}
			
			## update the R1 and R2 files for next round of fastqc
			$sampleInfo->{1} = $pair1Trimmed;
			$sampleInfo->{2} = $pair2Trimmed;
			
			$rerunFastqcFiles = $pair1Trimmed." ".$pair2Trimmed;
			
		}
		else{
			print STDERR "Cannot find the FastQC report $fastqcOut/$pair2FastqcZip\n";
			die;
		}
		
	}
	else{
		#run cutadapt for single end data
		system("echo Trimming file $sampleInfo->{1} from single end data
		echo Command: $cutadaptSE $adapterFwd $illuminaAdapters -o $pair1Trimmed $sampleInfo->{1}
		$cutadaptSE $adapterFwd $illuminaAdapters -o $pair1Trimmed $sampleInfo->{1}");
		
		if($? != 0){
			print STDERR "Cutadapt failed for single end data: $sampleInfo->{1}\n";
			die;
		}
		
		## update the R1 and R2 files for next round of fastqc
		$sampleInfo->{1} = $pair1Trimmed;
		$rerunFastqcFiles = $pair1Trimmed;
	}
	
	
	my $fqcDone = &fastQc($rerunFastqcFiles, $sampleInfo->{'fastqcOut'}."_trimmed");

	
}





#parse the fastqc report and return the adapter sequences present if any
sub getOverrepresentedSeqs{
	my $fqcData = shift @_;
	my $adapter = shift @_;
	# print STDERR "Addapter in: $adapter\n";
	
	open(my $fh, $fqcData) or die "Cannot open file $fqcData: $!";
	
	my $flag=0;
	
	while(<$fh>){
		if(/^>>Overrepresented sequences/){
			$flag = 1;
		}
		elsif(/^>>END_MODULE/){
			$flag = 0;
		}
		
		if($flag && /^(\w+)\t\d+\t\S+\t(Illumina|TruSeq|RNA PCR|ABI)/){
			$adapter.="-b $1 ";
		}
	}

	close($fh);
	
	my($filename, $dirs, $suffix) = fileparse($fqcData);
	rmdir($dirs);
	
	# print STDERR "Adapter out: $adapter\n";
	return $adapter;
}






1;

