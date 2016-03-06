#
#
# This script Parses Build Version numbers
# It expects version numbers following a pattern
# BuildNumber should look like $(BuildDefinitionName)_$(Date:yyyyMMdd)$(Rev:.r)
# Assembly numbers expected in pattern 1.0.C.D 
#
#
	[CmdletBinding(DefaultParameterSetName = 'SetVersions')]
	Param
	(
        [Parameter(Mandatory=$True)] [string]$SourceDirectory, 
	 	[Parameter(Mandatory=$True)] [string]$AssemblyVersion, 
		[Parameter(Mandatory=$True)] [string]$AssemblyFileVersion,
		[Parameter(Mandatory=$True)] [string]$AssemblyInformationalVersion,
		[Parameter()] [string]$BuildNumber = $env:BUILD_BUILDNUMBER
	)

	# write parameters
    Write-Host("** Received Parameters **")
    Write-Host("  SourceDirectory : ["+$SourceDirectory+"]") 
    Write-Host("  AssemblyVersion : ["+$AssemblyVersion+"]") 
	Write-Host("  AssemblyFileVersion : ["+$AssemblyFileVersion+"]")
	Write-Host("  AssemblyInformationalVersion : ["+$AssemblyInformationalVersion+"]")
	Write-Host("  BuildNumber : ["+$BuildNumber+"]")

    Write-Host("** End Received Parameters **") 

    # version numbers
	$parts = $BuildNumber.Split('_')
	$dateFromBuild = $BuildNumber.Split('_')[$parts.Length -1] # returns 20160328.5

	# splitting
	$yeari = $dateFromBuild.Substring(2, 2) # year part 10 from 2010
    $monthi = $dateFromBuild.Substring(4, 2) # month part 07
    $dayi = $dateFromBuild.Substring(6, 2) # day 27
    $revision = $dateFromBuild.Substring(9).PadLeft(3, '0') # revision part 9 or 10 or 11 etc.

    # concats
	$ym = $yeari + $monthi 
	$dr = $dayi + $revision            
	
	# parse the assembly version numbers based on expected template
	$assemblyVersion = $AssemblyVersion.Replace("C", $ym).Replace("D", $dr)
    $assemblyFileVersion = $AssemblyFileVersion.Replace("C", $ym).Replace("D", $dr)

	# write determined numbers
	Write-Host("Determined Assembly Version : ["+$assemblyVersion+"]")
	Write-Host("Determined Assembly File Version : ["+$assemblyFileVersion+"]")
	
	# find all AssemblyInfo.* files (C# and VB.NET)
	# $AllVersionFiles = Get-ChildItem $env:BUILD_SOURCESDIRECTORY AssemblyInfo.* -recurse
	$AllVersionFiles = Get-ChildItem $SourceDirectory AssemblyInfo.* -recurse

    

	foreach ($file in $AllVersionFiles) 
    { 
        Write-Host "== Updating AssemblyInfo File == " $file.FullName

		# remove possible read-only bit on the file
        Set-ItemProperty $file.FullName IsReadOnly $false

		$tmpFile = $file.FullName + ".tmp"

		get-content $file.FullName | 
        %{$_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyVersion(""$AssemblyVersion"")" } |
        %{$_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyFileVersion(""$AssemblyFileVersion"")" } |
		%{$_ -replace 'AssemblyInformationalVersion\(\"[\s\S]*\"\)', "AssemblyInformationalVersion(""$AssemblyInformationalVersion"")" }  > $tmpFile

		move-item $TmpFile $file.FullName -force
    }


