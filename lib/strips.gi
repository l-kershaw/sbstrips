InstallMethod(
    StripFamilyOfSbAlg,
    "for special biserial algebra",
    [ IsSpecialBiserialAlgebra ],
    function( sba )
        local
            fam;

        if HasStripFamilyOfSbAlg( sba ) then
            return StripFamilyOfSbAlg( sba );
        else
            fam := NewFamily( "StripFamilyForSbAlg" );
            fam!.sb_alg := sba;
            
            return fam;
        fi;
    end
);

InstallMethod(
    ReflectionOfStrip,
    "for a strip rep",
    [ IsStripRep ],
    function( strip )
        local
            data,       # Defining data of <strip>
            k, l,       # Integer variables 
            list,       # List variable (for the output)
            ori_list,   # Sublist of orientations in <data>
            sy_list;    # Sublist of syllables in <data>
            
        data := strip![1];
        l := Length( data );
        
        # The syllables are in the odd positions of <data>; the orientations in
        #  the even positions.
        sy_list := data{ Filtered( [ 1..l ], IsOddInt ) };
        ori_list := data{ Filtered( [ 1..l ], IsEvenInt ) };
        
        # <sy_list> and <ori_list> need to be reversed individually and then
        #  interwoven
        sy_list := Reversed( sy_list );
        ori_list := Reversed( ori_list );
        
        list := [1..l];
        for k in list do
            if IsOddInt( k ) then
                list[ k ] := sy_list[ Floor( k/2 ) ];
            elif IsEvenInt( k ) then
                list[ k ] := ori_list[ Floor( k/2 ) ];
            fi;
        od;
        
        return list;
    end
);

InstallMethod(
    \=,
    "for strips",
    \=,
    [ IsStripRep, IsStripRep ],
    function( strip1, strip2 )
        local
            data1, data2,           # Defining data of <strip1> and <strip2>
            l,                      # Integer variable (for a length of a list)
            ori_list1, ori_list2,   # Orientation list of <data1> and <data2>
            sy_list1, sy_list2;     # Syllable list of <data1> and <data2>
            
        data1 := strip1![1];
        data2 := strip2![1];
        
        if Length( data1 ) <> Length( data2 ) then
            return false;
        else
            l := Length( data1 );
            sy_list1 := data1{ Filtered( [ 1..l ], IsOddInt ) };
            ori_list1 := data1{ Filtered( [ 1..l ], IsEvenInt ) };
            sy_list2 := data2{ Filtered( [ 1..l ], IsOddInt ) };
            ori_list2 := data2{ Filtered( [ 1..l ], IsEvenInt ) };
            
            if ( sy_list1 = sy_list2 ) and ( ori_list1 = ori_list2 ) then
                return true;
            elif ( sy_list1 = Reversed( sy_list2 ) ) and
             ( sy_list1 = Reversed( sy_list2 ) ) then
                return true;
            else
                return false;
            fi;
        fi;
    end
);

InstallGlobalFunction(
    StripifyFromSyllablesAndOrientationsNC,
    "for a list of syllables and alternating orientations",
    function( arg )
        local
            data,       # Defining data of the strip to output
            fam,        # Strip family of <sba>
            len,        # Length of <arg>
            norm_sy,    # Syllable added in order to normalize
            norm_arg,   # Normalised version of <arg>
            sba,        # SB algebra from which the syllables are taken
            type;       # Type variable
        
        len := Length( arg );
        sba := SbAlgOfSyllable( arg[1] );
        
        # This is an NC function, so we can assume that the arguments are
        #      sy1, or1, sy2, or2, sy3, or3, ..., syN, orN
        #  where [ sy1, sy2, sy3, ..., syN ] are alternately peak- and valley-
        #  neighbour syllables and [ or1, or2, or3, ..., orN ] are alternately
        #  -1 and 1.
        
        # First, we normalize. This means putting a stationary trivial syllable
        #  with orientation -1 at the start and one with orientation 1 at the
        #  end if necessary and calling the function again
        
        if arg[2] <> -1 then
            norm_sy := SidestepFunctionOfSbAlg( sba )( arg[1] );
            norm_arg := Concatenation( [ norm_sy, -1 ], arg );
            
            Info( InfoDebug, 2, "Normalising on left, calling again..." );
            
            return CallFuncList(
            StripifyFromSyllablesAndOrientationsNC,
             norm_arg
             );
        elif arg[ len ] <> 1 then
            norm_sy := SidestepFunctionOfSbAlg( sba )( arg[ len - 1 ] );
            norm_arg := Concatenation( arg, [ norm_sy, 1 ] );
            
            Info( InfoDebug, 2, "Normalising on right, calling again..." );
            
            return CallFuncList(
            StripifyFromSyllablesAndOrientationsNC,
             norm_arg
             );
        fi;
        
        # Now we create the <IsStripRep> object.
        
        Info( InfoDebug, 2, "no normalisation needed, creating object..." );
        
        data := arg;
        fam := StripFamilyOfSbAlg( sba );
        type := NewType( fam, IsStripRep );
        
        return Objectify( type, [ data ] );
    end
);

InstallGlobalFunction(
    StripifyFromSbAlgPathNC,
    "for a nonstationary path in an SB algebra between two lists of integers",
    function( left_list, path, right_list )
        local
            1_sba,      # Multiplicative unit of <sba>
            2reg,       # 2-regular augmention of <quiv>
            cont,       # Contraction of <oquiv> (function <oquiv> --> <2reg>)
            i,          # Vertex variable (for source/target of a path)
            k, l, r,    # Integer variable (for entries of <left_list> or
                        #  <right_list>)
            len,        # Integer variable (for length of a path)
            linind,     # Set of <oquiv> paths with linearly independent res-
                        #  -idue in <sba>
            list,       # List variable, to store syllables and orientations
            matches,    # List of paths in <lin_ind> that lift <path>
            oquiv,      # Overquiver of <sba>
            over_path,  # Lift <path> to overquiver
            p,          # Path variable
            quiv,       # Ground quiver of <sba>
            ret,        # Retraction of <2reg> (function <2reg> --> <quiv> )
            sba;        # SB algebra to which <path> belongs
        
        sba := PathAlgebraContainingElement( path );
        1_sba := One( sba );
        
        quiv := QuiverOfPathAlgebra( OriginalPathAlgebra( sba ) );
        2reg := 2RegAugmentationOfQuiver( quiv );
        ret := RetractionOf2RegAugmentation( 2reg );
        oquiv := OverquiverOfSbAlg( sba );
        cont := ContractionOfOverquiver( oquiv );

        linind := LinIndOfSbAlg( sba );
        
        # Find the path <over_path> in <oquiv> whose <sba>-residue is <path>.
        #  (Recall that entries of <linind> are paths in <oquiv>. Applying
        #  <cont> and then <ret> turns them into entries of <quiv>. Multiplying
        #  by <1_sba> subsequently makes elements of <sba>.)
        matches := Filtered( linind, x -> ( 1_sba * ret( cont( x ) ) ) = path );
        if Length( matches ) <> 1 then
            Error( "I cannot find an overquiver path that lifts the given \
             path ", path, "! Contact the maintainer of the sbstrips package."
             );
        else
            over_path := matches[1];
        fi;

        # First, we normalise. If <left_list> has a last entry that is negative
        #  and/or <right_list> has a first entry that is positive, then we
        #  "absorb" those entries into <over_path>, remove them from their res-
        #  -pective lists, and call the function again.
        # (We need to be careful as <left_list> or <right_list> may be empty.
        
        if Length( left_list ) > 0 then
            l := left_list[ Length( left_list ) ];
            if l < 0 then
                i := TargetOfPath( over_path );
                len := LengthOfPath( over_path );
                over_path := PathByTargetAndLength( i, len - l );

                path := ret( cont( over_path ) )*1_sba;
                left_list := left_list{ [ 1..( Length( left_list ) - 1 ) ] };
                return StripifyFromSbAlgPathNC( left_list, path, right_list );
            fi;
        fi;
        
        if Length( right_list ) > 0 then
            r := right_list[1];
            if r > 0 then
                i := SourceOfPath( over_path );
                len := LengthOfPath( over_path );
                over_path := PathBySourceAndLength( i, len+r );
                
                path := ret( cont( over_path ) )*1_sba;
                right_list := right_list{ [ 2..( Length( right_list ) ) ] };
                return StripifyFromSbAlgPathNC( left_list, path, right_list  );
            fi;
        fi;
        
        # Now <left_list> is either empty or ends in a positive integer, and
        #  <right_list> is either empty or begins with a negative integer. We
        #  can turn the input into a syllable-and-orientation list to be
        #  handled by <StripifyFromSyllablesAndOrientationsNC>.
        
        list := [ over_path, 1 ];

        # Develop <list> on the right
        i := ExchangePartnerOfVertex( TargetOfPath( over_path ) );
        for k in [ 1..Length( right_list ) ] do
            if right_list[k] < 0 then
                p := PathByTargetAndLength( i, -( right_list[k] ) );
                list := Concatenation( list, [ p, -1 ] );
                i := ExchangePartnerOfVertex( SourceOfPath( p ) );
            elif
                right_list[k] > 0 then
                p := PathBySourceAndLength( i, right_list[k] );
                list := Concatenation( list, [ p, 1 ] );
                i := ExchangePartnerOfVertex( TargetOfPath( p ) );
            fi;
        od;
        
        # Develop <list> on the left
        i := ExchangePartnerOfVertex( SourceOfPath( over_path ) );
        for k in [ 1..Length( left_list ) ] do
            if Reversed( left_list )[k] < 0 then
                p := PathByTargetAndLength( i, -( Reversed( left_list )[k] ) );
                list := Concatenation( [p, 1], list );
                i := ExchangePartnerOfVertex( SourceOfPath( p ) );
            elif Reversed( left_list )[k] > 0 then
                p := PathBySourceAndLength( i, Reversed( left_list )[k] );
                list := Concatenation( [p, - 1], list );
                i := ExchangePartnerOfVertex( TargetOfPath( p ) );
            fi;
        od;

        # This gives a list paths in <oquiv> and orientations. Now we turn each
        #  path into a syllable. Almost all syllables are interior (ie, have
        #  pertubation term 0). The only exceptions are: the first syllable
        #  only if its orientation is -1 and; the last syllable only if its
        #  orientation is 1.
        for k in [ 1..Length( list ) ] do
            if IsOddInt( k ) then
                if ( (k = 1) and (list[k+1] = -1) ) then
                    list[k] := Syllabify( list[k], 1 );
                elif ( (k+1 = Length( list )) and (list[k+1] = 1) ) then
                    list[k] := Syllabify( list[k], 1 );
                else
                    list[k] := Syllabify( list[k], 0 );
                fi;
            fi;
        od;
        
        # Pass <list> to StripifyFromSyllablesAndOrientationsNC
        return CallFuncList(
         StripifyFromSyllablesAndOrientationsNC,
         list
         );
    end
);

InstallMethod(
    Display,
    "for a strip rep",
    [ IsStripRep ],
    function( strip )
        local
            data,   # Defining data of <strip>
            k;      # Integer variable
        
        data := strip![1];
        for k in [ 1..Length( data ) ] do
            if IsOddInt( k ) then
                if data[k+1] = -1 then
                    Print( data[k], "^-1" );
                elif data[k+1] = 1 then
                    Print( data[k] );
                fi;
            fi;
        od;
        Print( "\n" );
    end
);

InstallMethod(
    ViewObj,
    "for a strip rep",
    [ IsStripRep ],
    function( strip )
        local
            2reg,           # 2-regular augmentaion of <quiv>
            as_quiv_path,   # Local function that turns a syllable into the 
                            #  <quiv>-path that it represents
            cont,           # Contraction of <oquiv>
            data,           # Defining data of <strip>
            k,              # Integer variable
            quiv,           # Original quiver of <sba>
            oquiv,          # Overquiver of <sba>
            ret,            # Retraction of <2reg>
            sba,            # SB alg to which <strip> belongs
            sy;             # Syllable variable
    
        sba := FamilyObj( strip )!.sb_alg;
        
        quiv := QuiverOfPathAlgebra( OriginalPathAlgebra( sba ) );
        2reg := 2RegAugmentationOfQuiver( quiv );
        ret := RetractionOf2RegAugmentation( 2reg );
        
        oquiv := OverquiverOfSbAlg( sba );
        cont := ContractionOfOverquiver( oquiv );

        # Each syllable of <sba> represents a path of <sba>: this is the
        #  function that will tell you which
        as_quiv_path := function( sy )
            return ret( cont( UnderlyingPathOfSyllable( sy ) ) );
        end;
        
        # Print the strip so it looks something like
        #      (p1)^-1(q1) (p2)^-1(q2) (p3)^-1(q3) ... (pN)^-1(qN)
        data := strip![1];
        for k in [ 1..Length( data ) ] do
            if IsOddInt( k ) then
                sy := data[k];
                Print( "(", as_quiv_path( sy ), ")" );
                if data[k+1] = -1 then
                    Print( "^-1" );
                elif (data[k+1] = 1) and (IsBound( data[k+2] )) then
                    Print( " " );
                fi;
            fi;
        od;
    end
);

# <Stripify> has several methods. Ultimately, it will delegate to other
#  functions for all the hard work. Prior to delegation, it must check that its
#  input is in a legal format.
# In the first case, it will be given a list of syllables and orientations alt-
#  -ernately. This list must be nonempty and have even length for starters. The
#  syllables must alternately be peak and valley neighbours. The only boundary
#  syllables must appear at the boundary of the string; ie in the leftmost
#  position (which must have orientation -1) or the rightmost position (orien-
#  -tation 1). Further, the orientations must be alternately 1 and -1. 

InstallMethod(
    Stripify,
    "for a list, alternately of syllables and their orientations",
    [ IsList ],
    function( list )
        local
            fam,        # Family of a test syllable
            indices,    # List variable (for indices of interest)
            k,          # Index variable
            len,        # Length of <list>
            pert,       # Variable for perturbation term of a syllable
            sublist;    # Particular part of <list> (indexed by <indices>)

        # We perform some checks on <list> before delegating to the global
        #  function <StripifyFromSyllablesAndOrientationsNC>, namely verifying
        #  that <list> has even but nonzero length
        if IsEmpty( list ) then
            Info( InfoDebug, 2, "Input list is empty!" );
            TryNextMethod();
        elif not IsEvenInt( Length( list ) ) then
            Info( InfoDebug, 2, "Input list has odd length!" );
            TryNextMethod();
        else
            len := Length( list );
            
            # Check all entries in odd positions of <list> are syllables, all
            #  from the same family
            indices := Filtered( [1..len], IsOddInt );
            sublist := list{ indices };
            if false in List( sublist, IsSyllableRep ) then
                Info( InfoDebug, 2, "Input list contains a non-syllable!" );
                TryNextMethod();
            else
                fam := FamilyObj( sublist[1] );
                if false in List( sublist, x -> FamilyObj( x ) = fam ) then
                    Info( InfoDebug, 2, "Input syllable families disagree!" );
                    TryNextMethod();
                fi;
            fi;
            Info( InfoDebug, 2, "Syllables entered correctly" );
            
            # Check all entries in even positions of <list> are alternately
            #  either 1 or -1
            indices := Filtered( [1..len], IsEvenInt );
            sublist := list{ indices };
            if false in List( sublist, x -> ( x in [ 1, -1 ] ) ) then
                Info( InfoDebug, 2, "Orientations must be 1 or -1!" );
                TryNextMethod();
            else
                for k in [ 1..( Length( sublist ) ) ] do
                    if IsBound( sublist[k+1] ) then
                        if sublist[k]*sublist[k+1] <> -1 then
                            Info( InfoDebug, 2, "Orientations must alternate!"
                             );
                            TryNextMethod();
                        fi;
                    fi;
                od;
            fi;
            Info( InfoDebug, 2, "Orientations entered correctly" );
            
            # Check that all pairs
            #      (p_i)^-1(q_i)
            #  of consecutive syllables are peak neighbors and all pairs
            #      (q_i)(p_{i+1})
            #  are valley neighbours
            indices := Filtered( [1..len], IsOddInt );
            for k in indices do
                if IsBound( list[k+2] ) then
                    if list[k+1] = -1 then
                        if ( not
                         IsPeakCompatiblePairOfSyllables( list[k], list[k+2] )
                         ) then
                            Info( InfoDebug, 2, "Peak compatibility failure!");
                            TryNextMethod();
                        fi;
                    elif list[k+1] = 1 then
                        if ( not
                         IsValleyCompatiblePairOfSyllables(list[k], list[k+2])
                         ) then
                            Info( InfoDebug, 2,
                             "Valley compatibility failure!" );
                            TryNextMethod();
                        fi;
                    fi;
                fi;
            od;
            Info( InfoDebug, 2, "Peak and valley-compatibility holds!" );
        fi;

        # A nonzero syllable must be boundary iff it is either the leftmost
        #  syllable and has orientation -1 or the rightmost syllable and has
        #  orientation 1. Check this.
        indices := Filtered( [1..len], IsOddInt );
        for k in indices do
            pert := PerturbationTermOfSyllable( list[k] );
            if ( k = 1 and list[k+1] = -1 ) or
             ( k = Maximum( indices ) and list[k+1] = 1 )
             then
                if pert = 0 then
                    Info( InfoDebug, 2, "Interior syllable at boundary!" );
                    TryNextMethod();
                fi;
            else
                if pert = 1 then
                    Info( InfoDebug, 2, "Boundary syllable at interior!" );
                fi;
            fi;
        od;
        Info( InfoDebug, 2, "Interior/boundary syllables appropriate!" );
        
        # Check for virtual syllables. The only permitted appearance of virtual
        #  syllables is if <list> looks like
        #      [ <virtual syllable>, 1, <virtual syllable>, -1 ]
        indices := Filtered( [1..len], IsOddInt );
        sublist := list{ indices };
        if true in List( sublist, IsVirtualSyllable ) then
            if false in List( sublist, IsVirtualSyllable ) then
                Info( InfoDebug, 2,
                 "There are virtual syllables among nonvirtual ones!"
                 );
            if Length( sublist ) <> 2 then
                Info( InfoDebug, 2,
                 "There are too many virtual syllables!"
                 ):
                TryNextMethod();
            fi;
            if not ( list[2] = 1 and list[4] = -1 ) then
                Info( InfoDebug, 2,
                 "These virtual syllables have the wrong orientation!"
                 );
                TryNextMethod();
            fi;
            
            #
            # MAKE SOME "StripifyVirtualStripNC" FUNCTION OR SOMETHING!
            #
        fi;
        
        # All checks are complete; we delegate to another function for the hard
        #  work!
        return CallFuncList(
         StripifyFromSyllablesAndOrientationsNC,
         list
        );
    end
);

InstallMethod(
    SyzygyOfStrip,
    "for a strip",
    [ IsStripRep ],
    function( strip )
        local
            data,       # Underlying data of strip
            indices,    # List variable, for indices of interest
            j, k,       # Integer variables, for indices
            len,        # Length of <data>
            patch,      # Patch variable
            patch_list, # List variable, for patches
            sba,        # SB algebra of which <strip> is a strip
            summands,   # Integer variable
            sy_list,    # Syllable (sub)list of <data>
            syz_list,   # List whose entries are the defining data lists of
                        #  strips
            zero_patch, # Zero patch of <sba>

        data := strip![1];
        len := Length( data );
        indices := Filtered( [1..len], IsOddInt );
        sy_list := data{ indices };
        
        # We use <sy_list> to specify a list of patches, sandwiched between two
        #  copies of the zero patch of <sba>.
        
        sba := FamilyObj( strip )!.sb_alg;
        zero_patch := ZeroPatchOfSbAlg( sba );
        patch_list := [ zero_patch ];
        
        indices := [ 1..Length( sy_list ) ];
        for k in indices do
            if IsOddInt( k ) then
                patch := PatchifyByTop( sy_list[k], sy_list[k+1] );
                Add( patch_list, patch );
            fi;
        od;
        Add( patch_list, zero_patch );

        # We now read the syzygy strips off of the southern parts of
        #  <patch_list>, separating them at patches of string projectives
        
        syz_list := [ [ ] ];
        j := 1;
        
        for k in [ 2 .. ( Length( patch_list ) - 1 ) ] do
            if IsPatchOfStringProjective( patch_list[k] ) then
                if not IsZeroSyllable( patch_list[k]!.SW ) then
                    Append( syz_list[j], [ patch_list[k]!.SW, 1 ] );
                fi;
                Add( syz_list, [] );
                j := j + 1;
                if not IsZeroSyllable( patch_list[k]!.SE ) then
                    Append( syz_list[j], [ patch_list[k]!.SE, -1 ] );
                fi;
            elif IsPatchOfPinModule( patch_list[k] ) then
                if not IsZeroSyllable( patch_list[k]!.SW ) then
                    Append( syz_list[j], [ patch_list[k]!.SW, 1 ] );
                fi;
                if not IsZeroSyllable( patch_list[k]!.SE ) then
                    Append( syz_list[j], [ patch_list[k]!.SE, -1 ] );
                fi;
            fi;
        od;
        
        # Each entry of <syz_list> is a list of syllables and orientations.
        #  Remove the empty ones and <Stripify> the nonempty ones.
        j := 1;
        while j <= Length( syz_list ) do
            if IsEmpty( syz_list[j] ) then
                Remove( syz_list, j );
            else
                syz_list[j] := Stripify( syz_list[j] );
                j := j + 1;
            fi;
        od;
        
        return syz_list;
    end
);

InstallOtherMethod(
    SyzygyOfStrip,
    "for a list of strips",
    [ IsList ],
    function( list )
        if false in List( list, IsStripRep ) then
            TryNextMethod();
        else
            return List( list, SyzygyOfStrip );
        fi;
    end
);

#########1#########2#########3#########4#########5#########6#########7#########
