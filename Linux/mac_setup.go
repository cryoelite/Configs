package main

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

func checkAdmin() bool {
	_, err := os.Stat("/root")
	return err == nil
}

func downloadImage(imgPath, arch, arm64VMURL, amd64VMURL string) error {
	var url string
	if arch == "amd64" {
		url = amd64VMURL
	} else {
		url = arm64VMURL
	}

	fmt.Printf("Downloading %s\n", imgPath)
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	out, err := os.Create(imgPath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return err
	}

	fmt.Printf("Download completed successfully. Saved as '%s'.\n", imgPath)
	return nil
}

func setupImage(arch, imgPath, urlSHA256, arm64VMURL, amd64VMURL string) error {
	if _, err := os.Stat(imgPath); err == nil {
		fmt.Printf("%s exists, verifying SHA256 Checksum\n", imgPath)

		// Download the SHA256SUMS
		sha256File := "/tmp/SHA256SUMS"
		err = downloadImage(sha256File, arch, arm64VMURL, amd64VMURL)
		if err != nil {
			return err
		}

		calculatedChecksum, err := calculateChecksum(imgPath)
		if err != nil {
			return err
		}

		expectedChecksum, err := getExpectedChecksum(sha256File, imgPath)
		if err != nil {
			return err
		}

		fmt.Printf("Calculated checksum: %s\n", calculatedChecksum)
		fmt.Printf("Expected checksum: %s\n", expectedChecksum)

		if calculatedChecksum == expectedChecksum {
			fmt.Println("Checksum verified successfully! The file is valid.")
		} else {
			fmt.Println("Checksum verification failed! The file isn't up-to-date or corrupted.")
			return downloadImage(imgPath, arch, arm64VMURL, amd64VMURL)
		}
	} else {
		err := downloadImage(imgPath, arch, arm64VMURL, amd64VMURL)
		if err != nil {
			return err
		}
	}

	return nil
}

func calculateChecksum(filePath string) (string, error) {
	cmd := exec.Command("sha256sum", filePath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}
	return strings.Fields(string(output))[0], nil
}

func getExpectedChecksum(sha256File, imgPath string) (string, error) {
	file, err := os.Open(sha256File)
	if err != nil {
		return "", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasSuffix(line, imgPath) {
			return strings.Fields(line)[0], nil
		}
	}
	return "", fmt.Errorf("checksum not found for %s in %s", imgPath, sha256File)
}

func setupDisk(imgPath, diskPath, diskFolder, diskSize string) error {
	fmt.Printf("Setting up disk at %s\n", diskPath)

	err := os.MkdirAll(diskFolder, 0755)
	if err != nil {
		return err
	}

	fmt.Printf("Copying %s to %s\n", imgPath, diskPath)
	inputFile, err := os.Open(imgPath)
	if err != nil {
		return err
	}
	defer inputFile.Close()

	outputFile, err := os.Create(diskPath)
	if err != nil {
		return err
	}
	defer outputFile.Close()

	_, err = io.Copy(outputFile, inputFile)
	if err != nil {
		return err
	}

	fmt.Printf("Successfully finished generating %s\n", diskPath)

	fmt.Printf("Resizing %s\n", diskPath)
	cmd := exec.Command("qemu-img", "resize", diskPath, diskSize)
	err = cmd.Run()
	if err != nil {
		return err
	}

	fmt.Printf("Successfully resized %s to %s\n", diskPath, diskSize)
	return nil
}

func startQEMU(shouldCloudInit bool, vmName, memorySize, cpuCores, diskPath, seedImg, qemuPath, stateSavePath, mountDir string) {
	fmt.Println("Setting up and Starting QEMU")

	args := []string{
		"-name", vmName,
		"-machine", "accel=kvm",
		"-m", memorySize,
		"-smp", fmt.Sprintf("cores=%s", cpuCores),
		"-nographic",
		"-device", "virtio-net-pci,netdev=net0",
		"-netdev", "user,id=net0,hostfwd=tcp::2222-:22",
		"-drive", fmt.Sprintf("if=virtio,format=qcow2,file=%s", diskPath),
	}

	if shouldCloudInit {
		args = append(args, "-drive", fmt.Sprintf("if=virtio,format=raw,file=%s", seedImg))
	}

	cmd := exec.Command(qemuPath, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Start()
	if err != nil {
		fmt.Printf("Error starting QEMU: %s\n", err)
		return
	}

	fmt.Println("QEMU started. Note: Shutdown with 'shutdown -h now' inside the VM to save state.")
	err = cmd.Wait()
	if err != nil {
		fmt.Printf("Error waiting for QEMU: %s\n", err)
	}
}

func main() {
	// Check if running as root
	/* if !checkAdmin() {
		fmt.Println("Please run as root")
		os.Exit(1)
	} */

	// Configuration variables
	vmName := "auhydromy"
	memorySize := "8G"
	diskSize := "64G"
	diskFolder := "/mnt/vms"
	diskPath := fmt.Sprintf("%s/%s.img", diskFolder, vmName)
	cpuCores := "2"
	seedImg := "./seed.img"
	qemuPath := "/usr/bin/qemu-system-x86_64"
	stateSavePath := "/mnt/vms/state.sav"
	mountDir := "/mnt/github"
	arch := "amd64"
	imgPath := fmt.Sprintf("/tmp/ubuntu-oracular-server-cloudimg-%s.img", arch)
	arm64VMURL := "https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-arm64.img"
	amd64VMURL := "https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-amd64.img"
	urlSHA256 := "https://cloud-images.ubuntu.com/oracular/current/SHA256SUMS"

	// Setup image
	err := setupImage(arch, imgPath, urlSHA256, arm64VMURL, amd64VMURL)
	if err != nil {
		fmt.Println("Error setting up image:", err)
		return
	}

	// Setup disk
	err = setupDisk(imgPath, diskPath, diskFolder, diskSize)
	if err != nil {
		fmt.Println("Error setting up disk:", err)
		return
	}

	// Start QEMU
	startQEMU(true, vmName, memorySize, cpuCores, diskPath, seedImg, qemuPath, stateSavePath, mountDir)

	fmt.Println("Finished setting up VM. For SSH, follow https://askubuntu.com/a/497898/1701747 and then ssh with ssh root@localhost -p 2222")
}
