// Hose connector modules
// version 2022-09-24

fudgeFactor = 0.015;

//diameter1: Inner start diameter.
//diameter2: Inner end diameter.
//length: pipe length
//wallThickness1 Thickness of the walls at the start
//wallThickness2 Thickness of the walls at the end
//zPosition: Start Z position.
module Pipe(diameter1, diameter2, length, wallThickness1, wallThickness2, zPosition)
{
    difference () 
    {
        //outer cylinder
        translate([0, 0, zPosition])
        {
            cylinder(
                d1=diameter1+2*wallThickness1, 
                d2=diameter2+2*wallThickness2, 
                h=length);
        }
        
        //Inner cylinder to remove
        translate([0, 0, zPosition-fudgeFactor])
        {
             cylinder(
                d1=diameter1, 
                d2=diameter2,
                h=length + 2*fudgeFactor);
        }
    }
}

module TaperedPipe(diameter1, diameter2, length, wallThickness, zPosition)
{
    Pipe (
        diameter1,
        diameter2,
        length,
        wallThickness,
        wallThickness,
        zPosition);
}

module StraightPipe(diameter, length, wallThickness, zPosition)
{
    Pipe (
        diameter,
        diameter,
        length,
        wallThickness,
        wallThickness,
        zPosition);
}

module HalfConePipe(diameter, length, wallThickness1, wallThickness2, zPosition)
{
    Pipe (
        diameter,
        diameter,
        length,
        wallThickness1,
        wallThickness2,
        zPosition);
}

module ConeRing(centerDiameter, length, wallThickness1, wallThickness2, zPosition)
{
    difference () 
    {
        //outer cylinder
        translate([0, 0, zPosition])
        cylinder(
            d1=centerDiameter+wallThickness1, 
            d2=centerDiameter+wallThickness2, 
            h=length);
    
        //Inner cylinder to remove
        translate([0, 0, zPosition-fudgeFactor])
        cylinder(
            d1=centerDiameter-wallThickness1, 
            d2=centerDiameter-wallThickness2, 
            h=length + 2*fudgeFactor);
    }
}


module MagneticConnector(
    innerStartDiameter,
    innerEndDiameter,
    length,
    wallThickness,
    magnetDiameter,
    magnetThickness,
    magnetBorder,
    flangeThickness,
    magnetCount,
    alignmentRing,
    alignmentDepth,
    alignmentUpperWidth,
    alignmentLowerWidth,
    alignmentSideClearance,
    alignmentDepthClearance
)
{

    alignmentBorder = alignmentRing != "no" ? magnetBorder/2 : 0;
    magnetPosition = (innerStartDiameter + magnetDiameter) / 2 + magnetBorder +
        (alignmentRing != "no" ? alignmentBorder + alignmentUpperWidth : 0);
  
    fillet = flangeThickness;
    difference () 
    {
        //flange
        union() {
            TaperedPipe (
                innerStartDiameter,
                innerEndDiameter,
                length,
                wallThickness,
                0);

            // flange aound the magnets
            hull () {
                for (i = [0: magnetCount-1]) {
                    rotate ([0, 0, i * (360 / magnetCount)]) 
                    translate ([magnetPosition, 0, 0]) 
                    cylinder (d = magnetDiameter + magnetBorder * 2, flangeThickness);
                }
            }
            
            // protuding magent rung
            if(alignmentRing == "protruding")
            {
                AlignmentRing(
                    centerDiameter = innerStartDiameter + alignmentBorder*2 + alignmentUpperWidth,
                    alignmentDepth = alignmentDepth,
                    alignmentUpperWidth = alignmentUpperWidth,
                    alignmentLowerWidth = alignmentLowerWidth,
                    alignmentSideClearance = alignmentSideClearance,
                    alignmentDepthClearance = alignmentDepthClearance,
                    magnetBorder = magnetBorder
                );
            }
            
            // taper 
            intersection()
            {
                HalfConePipe (
                    diameter = innerEndDiameter,
                    length = fillet,
                    wallThickness1 = fillet - fudgeFactor,
                    wallThickness2 = 0,
                    zPosition= flangeThickness - fudgeFactor);  
                
                translate([0, 0, 0])
                {
                    // incase the connector is less 
                    cylinder(
                        d=innerEndDiameter*2, 
                        h=length);
                }
            }
        }
        
        //Magnet cut out
        for (i = [0: magnetCount-1]) {
            rotate ([0, 0, i* 360 / magnetCount]) 
            translate ([magnetPosition, 0, - fudgeFactor]) 
            cylinder (d = magnetDiameter, h = magnetThickness + fudgeFactor);
        }

        //Flange inner  
        translate([0, 0, -fudgeFactor])
            cylinder (
                d1 = innerStartDiameter, 
                d2 = innerEndDiameter,
                h = length + 2 * fudgeFactor);
        
        if(alignmentRing == "recessed")
        {
            // Create recessed alignment ring
            AlignmentRing(
                    centerDiameter = innerStartDiameter + alignmentBorder*2 + alignmentUpperWidth,
                    alignmentDepth = alignmentDepth,
                    alignmentUpperWidth = alignmentUpperWidth,
                    alignmentLowerWidth = alignmentLowerWidth,
                    alignmentSideClearance = 0,
                    alignmentDepthClearance = 0,
                    magnetBorder = magnetBorder);
        }
    }
}

module AlignmentRing(
    centerDiameter,
    alignmentDepth,
    alignmentUpperWidth,
    alignmentLowerWidth,
    alignmentSideClearance,
    alignmentDepthClearance,
    magnetBorder
)
{
    
//rotate_extrude()
//translate([45, 0, 0])
//circle(r = 4);
   
    
    ringHeight = 2*(alignmentDepth-alignmentDepthClearance);
    ringMaxWidth = (alignmentUpperWidth - alignmentSideClearance);
    ringMinWidth = (alignmentLowerWidth - alignmentSideClearance);
    intersection() 
    { 
        union() 
        {
              
            ConeRing (
                centerDiameter = centerDiameter, 
                length = alignmentDepth, 
                wallThickness1 = ringMaxWidth, 
                wallThickness2 = ringMinWidth, 
                zPosition = 0); 
            //Add a StraightPipe between the two to block clipping without impacting the angle of the cones.
            StraightPipe (
                diameter = centerDiameter - ringMaxWidth + fudgeFactor, 
                length = fudgeFactor, 
                wallThickness = ringMaxWidth- fudgeFactor, 
                zPosition = -fudgeFactor/2);
            ConeRing (
                centerDiameter = centerDiameter, 
                length = alignmentDepth, 
                wallThickness1 = ringMinWidth, 
                wallThickness2= ringMaxWidth, 
                zPosition = -alignmentDepth);
       } 

        translate([0, 0, -ringHeight/2])
        {
            cylinder(
                d=centerDiameter + alignmentUpperWidth, 
                h=ringHeight);
        }
    }
}

module HoseConnector(
    innerStartDiameter,
    innerEndDiameter,
    length,
    wallThickness,
    stopLength,
    stopWidth
)
{
    union() {
        //hose connector
        TaperedPipe (
            innerStartDiameter,
            innerEndDiameter,
            length,
            wallThickness,
            0);
        
        // Create the hose stop
        StraightPipe (
            innerEndDiameter + wallThickness,
            stopLength,
            stopWidth + wallThickness/2 + fudgeFactor,
            length - stopLength);
        
        HalfConePipe (
            innerEndDiameter + wallThickness,
            stopLength,
            0,
            stopWidth + wallThickness/2 + fudgeFactor,
            length - stopLength*2);
    }
}

module HoseAdapter(
    wallThickness = 2,
    drawAlignmentRing = "no",
    alignmentDepth = 2,
    alignmentUpperWidth = 3,
    alignmentLowerWidth = 0.5,
    alignmentSideClearance = 0.25,
    alignmentDepthClearance = .75,
    connector1Style= "hose",
    connector1Measurement= "inner",
    connector1Diameter = 0,
    connector1Length = 0,
    connector1Taper = 0,
    connector1StopThickness = 0,
    connector1StopLength = 0,
    connector1MagnetCount = 0,
    connector1MagnetDiameter = 0,
    connector1MagnetThickness = 0,
    connector1MagnetBorder = 0,
    connector1MagnetFlangeThickness = 0,
    connector1Ring= "no",
    transitionStyle = "tapered",
    transitionLength = 0,
    connector2Style = "hose",
    connector2Measurement = "inner",
    connector2Diameter = 0,
    connector2Length = 0,
    connector2Taper = 0,
    connector2StopThickness = 0,
    connector2StopLength = 0,
    connector2MagnetCount = 0,
    connector2MagnetDiameter = 0,
    connector2MagnetThickness = 0,
    connector2MagnetBorder = 0,
    connector2MagnetFlangeThickness = 0,
    connector2Ring = "no"
){
    end1InnerDiameter = connector1Measurement == "inner" ? connector1Diameter : connector1Diameter - wallThickness * 2;
    end2InnerDiameter = connector2Measurement == "inner" ? connector2Diameter : connector2Diameter - wallThickness * 2;

    //Apply taper, from small to big
    end1InnerStartDiameter = end1InnerDiameter - connector1Taper / 2;
    end1InnerEndDiameter = end1InnerDiameter + connector1Taper / 2;

    //Apply taper, from big to small
    end2InnerStartDiameter = end2InnerDiameter + connector2Taper / 2;
    end2InnerEndDiameter = end2InnerDiameter - connector2Taper / 2;
    
    if(drawAlignmentRing == "end1")
    {
        !AlignmentRing(
            centerDiameter = end1InnerStartDiameter + connector1MagnetBorder + alignmentUpperWidth,
            alignmentDepth = alignmentDepth,
            alignmentUpperWidth = alignmentUpperWidth,
            alignmentLowerWidth = alignmentLowerWidth,
            alignmentSideClearance = alignmentSideClearance,
            alignmentDepthClearance = alignmentDepthClearance,
            magnetBorder = connector1MagnetBorder);
    }

    if(drawAlignmentRing == "end2")
    {
        !AlignmentRing(
            centerDiameter = end2InnerStartDiameter + connector2MagnetBorder + alignmentUpperWidth,
            alignmentDepth = alignmentDepth,
            alignmentUpperWidth = alignmentUpperWidth,
            alignmentLowerWidth = alignmentLowerWidth,
            alignmentSideClearance = alignmentSideClearance,
            alignmentDepthClearance = alignmentDepthClearance,
            magnetBorder = connector2MagnetBorder);
    }

    //Create the start connector
    if(connector1Length > 0)
    {
        if(connector1Style == "mag")
        {
            //Create the flange on end 1
            MagneticConnector(
                innerStartDiameter = end1InnerStartDiameter,
                innerEndDiameter = end1InnerEndDiameter,
                length = connector1Length,
                wallThickness = wallThickness,
                magnetDiameter = connector1MagnetDiameter,
                magnetThickness = connector1MagnetThickness,
                magnetBorder = connector1MagnetBorder,
                flangeThickness = connector1MagnetFlangeThickness,
                magnetCount = connector1MagnetCount,
                alignmentRing = connector1Ring,
                alignmentDepth = alignmentDepth,
                alignmentUpperWidth = alignmentUpperWidth,
                alignmentLowerWidth = alignmentLowerWidth,
                alignmentSideClearance = alignmentSideClearance,
                alignmentDepthClearance = alignmentDepthClearance);
        }

        if(connector1Style == "hose")
        {
            HoseConnector(
                innerStartDiameter = end1InnerStartDiameter,
                innerEndDiameter = end1InnerEndDiameter,
                length = connector1Length,
                wallThickness = wallThickness,
                stopLength = connector1StopLength,
                stopWidth = connector1StopThickness);
        }
    }

    //Transition between connections
    if(transitionLength > 0)
    {
        if(transitionStyle == "flat")
        {
            transDiameter = min(end1InnerEndDiameter,  end2InnerStartDiameter);
            transThickness = abs(end1InnerEndDiameter - end2InnerStartDiameter)/2 + wallThickness;
        StraightPipe(
            diameter = transDiameter, 
            length = transitionLength, 
            wallThickness = transThickness, 
            zPosition = connector1Length);
        }
        else
        {
            TaperedPipe(
                diameter1 = end1InnerEndDiameter, 
                diameter2 = end2InnerStartDiameter, 
                length = transitionLength, 
                wallThickness = wallThickness, 
                zPosition = connector1Length);       
        }
    }

    // Create the end connector
    if(connector2Length > 0)
    {
        end2StartZ = connector1Length + transitionLength;

        translate([0, 0, end2StartZ+connector2Length])
        mirror ([0,0,1])    
        union() {    
            if(connector2Style == "mag")
            {
                MagneticConnector(
                    //Start and End are reversed as the flange is mirrored.
                    innerStartDiameter = end2InnerEndDiameter, 
                    innerEndDiameter = end2InnerStartDiameter,
                    length = connector2Length,
                    wallThickness = wallThickness,
                    magnetDiameter = connector2MagnetDiameter,
                    magnetThickness = connector2MagnetThickness,
                    magnetBorder = connector2MagnetBorder,
                    flangeThickness = connector2MagnetFlangeThickness,
                    magnetCount = connector2MagnetCount,
                    alignmentRing = connector2Ring,
                    alignmentDepth = alignmentDepth,
                    alignmentUpperWidth = alignmentUpperWidth,
                    alignmentLowerWidth = alignmentLowerWidth,
                    alignmentDepthClearance = alignmentDepthClearance);
            }
            
            if(connector2Style == "hose")
            {
                HoseConnector(
                    innerStartDiameter = end2InnerEndDiameter,
                    innerEndDiameter = end2InnerStartDiameter,
                    length = connector2Length,
                    wallThickness = wallThickness,
                    stopLength = connector2StopLength,
                    stopWidth = connector2StopThickness);
            }
        }
    }
}
