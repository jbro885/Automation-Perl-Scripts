#!/usr/bin/perl -w

use strict;
use XML::Twig;
use XML::Parser;
use XML::SemanticDiff;
use Spreadsheet::ParseExcel;
use Data::Dumper;

my @results;
my %results;
my %source_mapping;

#****opens up Excel file******
my $parser = Spreadsheet::ParseExcel->new;
#my $workbook = $parser->parse('C:\\CincinnatiFinancial\\Excel.xls');
my $workbook = $parser->parse('Excel.xls');

#*****error message if file cannot open******
if (!defined $workbook) {
  die $parser->error(), ".\n";
} 

#******this gets the Source's XML parent and children*************
#******using the Product Model Requirements Excel file************
for my $worksheet ($workbook->worksheets())
  {
  my $i = 0;
  my ($row_min, $row_max) = $worksheet->row_range();
  my ($col_min, $col_max) = $worksheet->col_range();
    
  for my $row ($row_min .. $row_max)
    {
    my @array;
    my $twig;
    my $parent;
    my $children;
       
    for my $col ($col_min .. $col_max)
      {
      my $cell = $worksheet->get_cell( $row, $col );
      next unless $cell;

      #*****gets the value of each Excel cell****** 
      $parent = $cell->value if $col eq '1';
      $children = $cell->value if $col eq '2';

      #******creates a source mapping hash with key as parent and children*****
      #******only if parent and child both exist******** 
      $source_mapping{$parent}->{'children'} = $children if $parent && $children;
      }
      
     #print "end of 2 ";
     #print Dumper \%source_mapping;
     foreach my $k (keys %source_mapping)
       {
       #***the twig will include just the root and selected Source XML parents****
       #***this gets the start of the tree/path for the XML*****
       #***basically gets the Source's XML parent****
       $twig= XML::Twig->new(  
       twig_roots   => { 'CFXML/policy/'.$k => \&source_check_n_save
                   
          });
       $twig->parsefile( 'building_coverage.xml');   
       }
     }                
  }    
  
sub source_check_n_save 
  { 
    my( $twig, $elt)= @_;
    
    foreach my $parent (keys %source_mapping)
      {
      foreach my $children (keys %{$source_mapping{$parent}})
        {
         #*****now we can get the Source's XML children******
         #*****and check their data values*******
         my $xml_child = $source_mapping{$parent}{$children};
      #   print $xml_child;
         
         #*****gets the value of the Source's XML children****                  
         my $data = $elt->children_text($xml_child);
         push @results, $children;
         
         #*****stores Source's XML parent, child, and data*****
         #*****in a global hash reference****
         $results{$parent}->{$xml_child} = $data;
         $twig->purge;
        #print Dumper \@results;
        
        }
      }
    }
    
print Dumper \%results;
    
    
       