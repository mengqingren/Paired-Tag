#!/usr/bin/perl
use strict;
use warnings;

my $metadata = "path-to-metadata"; ## nuclei meta with barcode of pass filter cells, barcode in the first column.
my $pre_mtx = "path-to-raw-matrix"; ## raw matrix
my $prefix = "prefix-of-filtered-matrix"; ## prefix of output filtered matrix

open IN, $metadata or die $!;

system("mkdir $prefix\_filtered");
open OUT, ">$prefix\_filtered/barcodes.tsv" or die $!;
<IN>;
my $i = 0;
my %new_cell_id;
while(<IN>){
	my @tmp = split/\s+/, $_;
	$i++;
	my $cell_id = $tmp[0];
	$new_cell_id{$cell_id} = $i;
	print OUT "$cell_id\n";
}
close IN;
close OUT;


open IN, "$pre_mtx/barcodes.tsv";
my %old_cell_id;
$i = 0;
while(<IN>){
	chomp;
	$i++;
	$old_cell_id{$i} = $_;
}
close IN;

open IN, "$pre_mtx/genes.tsv" or die $!;
my %old_gene_list;
$i = 0;
while(<IN>){
	chomp;
	$i++;
	$old_gene_list{$i} = $_;
}
close IN;

my %hash;
my %gene_hits;

open IN, "$pre_mtx/matrix.mtx" or die $!;
my $n_cells = keys %new_cell_id;
my $n_genes = 0;
my $n_values = 0;
<IN>;
<IN>;
<IN>;
while(<IN>){
	chomp;
	my @tmp = split/\s+/, $_;
	my $cell_idx = $tmp[1];
	my $gene_idx = $tmp[0];
	my $value = $tmp[2];
	my $cell_id = $old_cell_id{$cell_idx};
	my $gene_id = $old_gene_list{$gene_idx};
	next if not exists $new_cell_id{$cell_id};
	$hash{$gene_id}{$cell_id} = $value;
	$gene_hits{$gene_id}{$cell_id} = 1;
}
close IN;

my %new_gene_list;
$i = 0;
open OUT, ">$prefix\_filtered/genes.tsv" or die $!;
foreach my $gene_id (sort keys %gene_hits){
	my $n_cells = keys %{$gene_hits{$gene_id}};
	next if $n_cells < 1;
	$i++;
	$new_gene_list{$gene_id} = $i;
	$n_values += $n_cells;
	print OUT "$gene_id\n";
}
close OUT;

$n_genes = keys %new_gene_list;

open OUT, ">$prefix\_filtered/matrix.mtx" or die $!;
print OUT "\%\%MatrixMarket matrix coordinate real general\n\%\n";
print OUT "$n_genes $n_cells $n_values\n";
foreach my $gene_id(keys %new_gene_list){
	my $gene_idx = $new_gene_list{$gene_id};
	foreach my $cell_id (keys %new_cell_id){
		next if not exists $hash{$gene_id}{$cell_id};
		my $cell_idx = $new_cell_id{$cell_id};
		my $value = $hash{$gene_id}{$cell_id};
		my $output = "$gene_idx $cell_idx $value\n";
		print OUT $output;
	}
}
close OUT;






