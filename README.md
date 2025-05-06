# Aztec Sequencer Setup

Aztec Sequencer Setup is an automated tool designed to streamline the setup and management of Aztec Sequencer nodes on the Alpha Testnet. It provides a user-friendly interface for installing and configuring Aztec nodes with minimal manual intervention.

## Features

- **Automated Node Setup**: Handles complete installation and configuration of Aztec Sequencer
- **Multiple Network Support**: Supports Alpha Testnet deployment
- **Easy Configuration**: Simple setup process with minimal user input required
- **Docker Integration**: Utilizes Docker for containerized deployment
- **Secure Key Management**: Secure handling of validator keys and RPC URLs
- **Error Handling**: Robust error handling and logging system

## Requirements

- Ubuntu/Debian-based Linux OS (18.04 or later recommended)
- Root or sudo privileges
- Internet connection (minimum 25 Mbps upload)
- Hardware Requirements:
  - Minimum 8 CPU cores
  - Minimum 16GB RAM
  - Minimum 100GB free disk space
  - SSD recommended for better performance
- Required Services:
  - L1 Execution Client (EL) RPC URL (Sepolia Testnet)
  - L1 Consensus Client (CL) RPC URL (Sepolia Testnet)
  - Validator Private Key
  - Blob Sink URL (optional)

## Installation & Usage

### One-line Installation

```bash
git clone https://github.com/azurezren/Aztec-Auto-Node.git && cd Aztec-Auto-Node && chmod +x aztec.sh && ./aztec.sh
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/azurezren/Aztec-Auto-Node.git
   cd Aztec-Auto-Node
   ```

2. Make the script executable:
   ```bash
   chmod +x aztec.sh
   ```

3. Run the setup script:
   ```bash
   sudo ./aztec.sh
   ```

## Tutorial: Obtaining RPC URLs

### L1 Execution Client (EL) RPC URL

1. Sign up or log in at [Alchemy](https://dashboard.alchemy.com/)
2. Create a new app:
   - Click "Create App"
   - Select "Ethereum" as the chain
   - Select "Sepolia" as the network
   - Give your app a name (e.g., "Aztec Sequencer")
   - Click "Create App"
3. Once your app is created, click on "View Key"
4. Copy the HTTPS URL, which should look like:
   ```
   https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
   ```

### L1 Consensus Client (CL) RPC URL

1. Sign up or log in at [DRPC](https://drpc.org/)
2. Create an API key:
   - Go to the "API Keys" section
   - Click "Create API Key"
   - Give your key a name (e.g., "Aztec Sequencer")
   - Select "Sepolia" network
3. Once your key is created, copy the HTTPS URL, which should look like:
   ```
   https://lb.drpc.org/ogrpc?network=sepolia&dkey=YOUR_API_KEY
   ```

### Alternative RPC Providers

You can also use other RPC providers such as:

- [Infura](https://infura.io/)
- [QuickNode](https://www.quicknode.com/)
- [Ankr](https://www.ankr.com/)
- [Chainstack](https://chainstack.com/)

Follow a similar process on these platforms to obtain your RPC URLs for the Sepolia testnet.

## Configuration

The script will prompt you for:

1. **L1 Execution Client RPC URL**
   - This URL should be for the Sepolia testnet
   - Must be HTTPS
   - Should have sufficient rate limits

2. **L1 Consensus Client RPC URL**
   - This URL should be for the Sepolia testnet
   - Must be HTTPS
   - Should support WebSocket connections

3. **Validator Private Key**
   - Must be a 64-character hexadecimal string
   - Can be provided with or without 0x prefix
   - The script will automatically add 0x prefix if missing

4. **Blob Sink URL** (Optional)
   - Used for storing blob data
   - Only required if you want to enable blob storage

## Checking Node Status

After installation, you can check your node's status:

```bash
docker-compose ps
```

Your node data is stored in the `data` directory created in the same location as the script.

## Troubleshooting

If you encounter issues:

1. Check your Docker installation:
   ```bash
   docker --version
   docker-compose --version
   ```

2. Verify your RPC URLs are correct and working:
   ```bash
   curl -I "YOUR_RPC_URL"
   ```

3. Check Docker logs for errors:
   ```bash
   docker-compose logs -f
   ```

4. Ensure your server has enough resources:
   - At least 8 CPU cores
   - 16GB RAM
   - 100GB free disk space
   - 25 Mbps upload

5. Check firewall settings to ensure the required ports are open:
   - Port 8080 (HTTP)
   - Port 9000 (WebSocket)

## Security Best Practices

1. **Private Key Security**
   - Never share your validator private key
   - Store it in a secure location
   - Consider using hardware wallets for key management

2. **RPC URL Security**
   - Keep your RPC URLs secure
   - Use rate-limited endpoints
   - Consider using private RPC services

3. **System Security**
   - Regularly update your system
   - Keep Docker and dependencies updated
   - Run in a secure environment
   - Use strong passwords for any third-party services

4. **Data Security**
   - Back up your node data regularly
   - Consider using encrypted storage
   - Implement proper access controls

## Error Handling

The setup script includes comprehensive error handling for:

1. Network connectivity issues
   - Automatic retries for connection failures
   - Connection validation before proceeding

2. Docker installation failures
   - Detailed error messages
   - Suggested fixes
   - Automatic cleanup of failed installations

3. Configuration errors
   - Input validation
   - Error recovery options
   - User confirmation prompts

4. API rate limiting
   - Automatic detection
   - Suggested solutions
   - Retry mechanisms

## Additional Resources

- [Aztec Documentation](https://docs.aztec.network/)
- [Aztec Discord](https://discord.gg/aztec)
- [Aztec Forum](https://forum.aztec.network/)

## Version Information

- Script version: v0.85.0-alpha-testnet.5
- Compatible with Aztec Protocol version: 0.85.0-alpha-testnet.5

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This is an Alpha Testnet setup. It's not meant for production use and may have bugs or issues. Use at your own risk.
