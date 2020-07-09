InstallMethod(
    SyllableFamilyOfSbAlg,
    "for a special biserial algebra",
    [ IsSpecialBiserialAlgebra ],
    function( sba )
        local
            fam;    # Family variable

        if HasSyllableFamilyOfSbAlg( sba ) then
            return SyllableFamilyOfSbAlg( sba );
        else
            fam := NewFamily( "SyllableFamilyForSbAlg" );
            fam!.sb_alg := sba;
            
            return fam;
        fi;
    end
);

InstallMethod(
    \=,
    "for syllables",
    \=,
    [ IsSyllableRep, IsSyllableRep ],
    function( sy1, sy2 )
        if ( sy1!.path = sy2!.path and
         sy1!.perturbation = sy2!.perturbation and
         sy1!.sb_alg = sy2!.sb_alg ) then
            return true;
        else
            return false;
        fi;
    end
);

InstallMethod(
    \<,
    "for syllables",
    \=,
    [ IsSyllableRep, IsSyllableRep ],
    function( sy1, sy2 )
        local
            ep1, ep2,       # Perturbation terms of <sy1> and <sy2>
            i1, i2,         # Sources of <path1> and <path2>
            len1, len2,     # Lengths of <path1> and <path2>
            path1, path2;   # Underlying paths of <sy1> and <sy2>
           
        # The zero syllable is the <-minimal syllable
        if IsZeroSyllable( sy1 ) and ( not IsZeroSyllable(sy2) ) then
            return true;
        elif ( not IsZeroSyllable(sy1) ) and IsZeroSyllable( sy2 ) then
            return false;
            
        # The order is strict, not reflexive
        elif sy1 = sy2 then
            return false;
            
        # If all of the above fails, then we are dealing with distinct
        #  syllables from the same SB algebra, neither of which are the zero 
        #  syllable. In this case, we construct a tuple of data for each
        #  syllable and compare the tuples lexicographically.
        else
            path1 := sy1!.path;
            path2 := sy2!.path;
            i1 := SourceOfPath( path1 );
            i2 := SourceOfPath( path2 );
            len1 := LengthOfPath( path1 );
            len2 := LengthOfPath( path2 );
            ep1 := sy1!.perturbation;
            ep2 := sy2!.perturbation;
            
            return [ i1, len1, ep1 ] < [ i2, len2, ep2 ];
        fi;
    end
);

InstallMethod(
    SyllableSetOfSbAlg,
    "for special biserial algebras",
    [ IsSpecialBiserialAlgebra ],
    function( sba )
        local
            a_i, b_i,       # <i>th terms of <a_seq> and <b_seq>
            a_seq, b_seq,   # Integer and bit sequences of <source_enc>
            ep,             # Bit variable for perturbation
            i,              # Vertex variable
            l,              # Length variable
            obj,            # Object to be made into a syllable, or data therof
            oquiv,          # Overquiver of <sba>
            set,            # List variable
            source_enc,     # Source encoding of permissible data of <sba>
            type;           # Type variable

        if HasSyllableSetOfSbAlg( sba ) then
            return SyllableSetOfSbAlg( sba );
        else
            oquiv := OverquiverOfSbAlg( sba );
            type := NewType(
             SyllableFamilyOfSbAlg( sba ),
             IsComponentObjectRep and IsSyllableRep
             );
             
            set := Set( [ ] );

            # Create zero syllable
            obj := rec(
             path := Zero( oquiv ),
             perturbation := fail,
             sb_alg := sba
            );
            
            ObjectifyWithAttributes(
             obj, type,
             IsZeroSyllable, true,
             IsStableSyllable, false,
             IsSyllableWithStableSource, false,
             IsUltimatelyDescentStableSyllable, false
            );
            
            AddSet( set, obj );
            
            # Create nonzero syllables

            # Nonzero syllables correspond to tuples [ i, l, ep ] satisfying
            #      0 < l + ep < a_i + b_i + ep,
            #  where a_i and b_i are the <i>th terms of <a_seq> and <b_seq>.
            #  Such tuples can be enumerated. The variables <i> and <ep> have
            #  finite ranges so we can range over them first, and then range
            #  over values of <l> that do not exceed the upper inequality.

            source_enc := SourceEncodingOfPermDataOfSbAlg( sba );
            a_seq := source_enc[1];
            b_seq := source_enc[2];
            
            for i in VerticesOfQuiver( oquiv ) do
                a_i := a_seq.( String( i ) );
                b_i := b_seq.( String( i ) );
                
                for ep in [ 0, 1 ] do
                    l := 0;
                    while l + ep < a_i + b_i + ep do
                        if 0 < l + ep then
                            obj := rec(
                             path := PathBySourceAndLength( i, l ),
                             perturbation := ep,
                             sb_alg := sba
                             );
                            ObjectifyWithAttributes(
                             obj, type,
                             IsZeroSyllable, false,
                             IsStableSyllable, ( ep = 0 ),
                             );
                            MakeImmutable( obj );
                            AddSet( set, obj );
                        fi;
                        l := l + 1;
                    od;
                od;
            od;
            
            MakeImmutable( set );
            return set;
        fi;
    end
);

InstallMethod(
    SbAlgOfSyllable,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        return FamilyObj( sy )!.sb_alg;
    end
);

InstallMethod(
    Syllabify,
    "for a path and a perturbation term",
    [ IsPath, IsInt ],
    function( path, int )
        local
            matches,    # List variable
            oquiv,      # Quiver containing <path>
            sba,        # SB algebra of which <oquiv> is (hopefully) overquiver
            syll_set;   # Syllable family of <sba>
        
        oquiv := QuiverContainingPath( path );
        if not IsOverquiver( oquiv ) then
            TryNextMethod();
        elif not ( int in [ 0,1 ] ) then
            TryNextMethod();
        else
            sba := SbAlgOfOverquiver( oquiv );
            syll_set := SyllableSetOfSbAlg( sba );
            matches := Filtered( syll_set,
             x -> (x!.path = path) and (x!.perturbation = int)
             );
            if Length( matches ) <> 1 then
                Error( "No syllables match this description!" );
            else
                return matches[1];
            fi;
        fi;
    end
);

InstallOtherMethod(
    Syllabify,
    "for the zero path and the boolean <fail>",
    [ IsZeroPath, IsBool ],
    function( zero, bool )
        if not ( bool = fail ) then
            TryNextMethod();
        else
            return Syllabify( zero, bool );
        fi;
    end
);

InstallMethod(
    ZeroSyllableOfSbAlg,
    "for special biserial algebras",
    [ IsSpecialBiserialAlgebra ],
    function( sba )
        if HasZeroSyllableOfSbAlg( sba ) then
            return ZeroSyllableOfSbAlg( sba );
        else
            return Syllabify( Zero( OverquiverOfSbAlg( sba ) ), fail );
        fi;
    end
);

InstallMethod(
    UnderlyingPathOfSyllable,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        return sy!.path;
    end
);

InstallMethod(
    PerturbationTermOfSyllable,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        return sy!.perturbation;
    end
);

InstallMethod(
    IsStableSyllable,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        if HasIsStableSyllable( sy ) then
            return IsStableSyllable( sy );
        else
            if PerturbationTermOfSyllable( sy ) = fail then
                return fail;
            else
                return ( PerturbationTermOfSyllable( sy ) = 0 );
            fi;
        fi;
    end
);

InstallMethod(
    IsSyllableWithStableSource,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        local
            path;   # Underlying path of <sy>
            
        if HasIsSyllableWithStableSource( sy ) then
            return IsSyllableWithStableSource( sy );
        elif IsZeroSyllable( sy ) then
            return fail;
        else
            path := UnderlyingPathOfSyllable( sy );
            return IsRepresentativeOfCommuRelSource( SourceOfPath( path ) );
        fi;
    end
);

InstallMethod(
    DescentFunctionOfSbAlg,
    "for special biserial algebras",
    [ IsSpecialBiserialAlgebra ],
    function( sba )
        local
            desc;   # Function variable
        if HasDescentFunctionOfSbAlg( sba ) then
            return DescentFunctionOfSbAlg( sba );
        else
            desc := function( sy )
                local
                    a_i1, b_i1,     # <i1>th terms of <a_i1> and <b_i1>
                    a_i2, b_i2,     # <i2>th terms of <a_i2> and <b_i2>
                    a_seq, b_seq,   # Integer and bit sequences of permissible
                                    #  data of <sba>
                    ep1, ep2,       # Bit variables
                    i1, i2,         # Vertex variables
                    l1, l2,         # Length variables
                    path1, path2;   # Path variables

                if not ( sba = FamilyObj( sy )!.sb_alg ) then
                    TryNextMethod();
                else
                    if IsZeroSyllable( sy ) then
                        return sy;
                    else
                        # Write <sy> as tuple [ i1, l1, ep1 ]
                        path1 := UnderlyingPathOfSyllable( sy );
                        i1 := SourceOfPath( path1 );
                        l1 := LengthOfPath( path1 );
                        ep1 := PerturbationTermOfSyllable( sy );
                        
                        # Obtain <i1>th terms in permissble data of <sba>
                        a_seq := SourceEncodingOfPermDataOfSbAlg( sba )[1];
                        b_seq := SourceEncodingOfPermDataOfSbAlg( sba )[2];
                        
                        a_i1 := a_seq.( String( i1 ) );
                        b_i1 := b_seq.( String( i2 ) );
                        
                        # Descent sends [ i1, l1, ep1 ] to
                        #  [ i1 - ( l1 + ep1 ),  a_i1 - ( l1 + ep1 ),  b_i1 ]
                        #  provided that this latter tuple is a syllable. We
                        #  calculate these three values -- respectively call
                        #  them <i2>, <l2> and <ep2> -- and verify that they
                        #  specify a syllable
                        
                        i2 := 1RegQuivIntAct( i1, -(l1 + ep1) );
                        l2 := a_i1 - ( l1 + ep1 );
                        ep2 := b_i2;
                        
                        a_i2 := a_seq.( String( i2 ) );
                        b_i2 := b_seq.( String( i2 ) );
                        
                        if ( 0 < l2 + ep2 ) and
                         ( l2 + ep2 < a_i2 + b_i2 + ep2 ) then
                            path2 := PathBySourceAndLength( i2, l2 );
                            return Syllabify( path2, ep2 );
                        else
                            return ZeroSyllableOfSbAlg( sba );
                        fi;                        
                        
                    fi;
                fi;
            end;
            
            return desc;
        fi;
    end
);

InstallMethod(
    SidestepFunctionOfSbAlg,
    "for special biserial algebra",
    [ IsSpecialBiserialAlgebra ],
    function( sba )
        local
            sidestep;   # Function variable

        if HasSidestepFunctionOfSbAlg( sba ) then
            return SidestepFunctionOfSbAlg( sba );
        else
            sidestep := function( sy )
                local
                    i, i_dagger;    # Vertex variable 

                # Verify that input <sy> is a syllable
                if not IsSyllableRep( sy ) then
                    TryNextMethod();
                    
                # The zero syllable is a fixpoint of the function
                elif IsZeroSyllable( sy ) then
                    return sy;

                # The source of a the underlying path of a nonzero input
                #  syllable determines what its sidestep image is
                else
                    i := SourceOfPath( UnderlyingPathOfSyllable( sy ) );
                    i_dagger := ExchangePartnerOfVertex( i );
                    return Syllabify(
                     PathBySourceAndLength( i_dagger , 0 ),
                     1
                     );
                fi;
            end;
            
            return sidestep;
        fi;
    end
);

InstallMethod(
    String,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        local
            path,           # Underlying path of <sy>
            pert;           # Perturbation term of <sy>

        if IsZeroSyllable( sy ) then
            return "( )";

        else
            # The returned string should look something like "( p, ep )"
            path := UnderlyingPathOfSyllable( sy );
            pert := PerturbationTermOfSyllable( sy );

            return Concatenation(
             "( ",  String( path ), ", ", String( pert ), " )"
             );
        fi;
    end
);

InstallMethod(
    IsUltimatelyDescentStableSyllable,
    "for syllables",
    [ IsSyllableRep ],
    function( sy )
        local
            desc,       # Descent function of <sba>
            latest,     # Latest term of <orbit>
            next,       # Next term of <orbit>
            orbit,      # <desc>-orbit of <sy>
            s,          # Syllable variable
            sba,        # SB algebra for which <sy> is a syllable
            tail,       # Periodic tail of <orbit>
            tail_start, # Index at which repeated syllable first appears
            value,      # Value of property for another syllable
            zero_syll;  # Zero syllable of <sba>

        # Remember that for zero syllables that this property is set (to
        #  <false>) at creation
        if HasIsUltimatelyDescentStableSyllable( sy ) then
            return IsUltimatelyDescentStableSyllable( sy );

        else
            sba := sy!.sb_alg;
            desc := DescentFunctionOfSbAlg( sba );
            zero_syll := ZeroSyllableOfSbAlg( sba );
            orbit := [ sy ];
            
            # This property is constant along <desc>-orbits. So calculate the
            #  <desc>-orbit of <sy> until either you find a syllable for which
            #  this property has been set -- in which case you return that
            #  answer -- or you find a repeat in the orbit. Remember that one 
            #  of these possibilities is bound to happen because that there are
            #  only finitely many syllables for <sba>!

            while IsDuplicateFreeList( orbit ) do
                latest := orbit[ Length( orbit ) ];
                next := desc( latest );

                # If the value of <IsUltimatelyDescentStableSyllable> is known
                #  for some later term in the <desc>-orbit of <sy>, then before
                #  you return this value for <sy> itself, set this value of the
                #  property for the other terms in the orbit.

                if HasIsUltimatelyDescentStableSyllable( latest ) then
                    value := IsUltimatelyDescentStableSyllable( latest );
                    for s in Filtered( orbit, x -> x <> sy ) do
                        SetIsUltimatelyDescentStableSyllable( s, value );
                    od;
                    
                    return value;
                fi;
            od;

            # The above case will catch all <desc>-transient syllables (see the
            #  above remark about the zero syllable), and so by now <sy> must
            #  be <desc>-preperiodic. We thus restrict our attention to the
            #  periodic part of the forward orbit of <sy> and look for any
            #  unstable syllables.

            latest := orbit( Length( orbit ) );
            tail_start := Position( orbit, latest );
            tail := orbit{ [ tail_start..Length( orbit ) ] };

            return not ( false in List( tail, IsStableSyllable ) );
        fi;
    end
);

#########1#########2#########3#########4#########5#########6#########7#########








